const {FieldValue, Timestamp} = require("firebase-admin/firestore");
const {HttpsError} = require("firebase-functions/v2/https");

const DUPLICATE_RESERVATION_MESSAGE =
  "この時間は既に予約されています。\n別の時間を選択してください。";
const DEFAULT_MENU_DURATION_MINUTES = 60;

function requireString(data, fieldName) {
  const value = data?.[fieldName];
  if (typeof value !== "string" || value.trim() === "") {
    throw new HttpsError(
        "invalid-argument",
        `${fieldName} is required.`,
    );
  }
  return value.trim();
}

function requireReservationDateTime(data) {
  const value = data?.reservationDateTimeMillis;
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new HttpsError(
        "invalid-argument",
        "reservationDateTimeMillis must be a positive integer.",
    );
  }
  return Timestamp.fromMillis(value);
}

function reservationSlotId(reservationDateTime) {
  return reservationDateTime.toMillis().toString();
}

async function createWebReservation(db, input) {
  const shopId = requireString(input, "shopId");
  const menuId = requireString(input, "menuId");
  const customerName = requireString(input, "customerName");
  const customerPhone = requireString(input, "customerPhone");
  const customerEmail = requireString(input, "customerEmail");
  const reservationDateTime = requireReservationDateTime(input);

  const shopRef = db.collection("shops").doc(shopId);
  const reservationsRef = shopRef.collection("reservations");
  const reservationRef = reservationsRef.doc();
  const slotRef = shopRef
      .collection("reservationSlots")
      .doc(reservationSlotId(reservationDateTime));
  const menusRef = db.collection("menus");
  const menuQuery = menusRef
      .where("shopId", "==", shopId)
      .where("menuId", "==", menuId)
      .limit(1);
  const menuByIdRef = menusRef.doc(menuId);
  const duplicateQuery = reservationsRef
      .where("reservationDateTime", "==", reservationDateTime)
      .limit(1);

  await db.runTransaction(async (transaction) => {
    const [
      shopSnapshot,
      menuQuerySnapshot,
      menuByIdSnapshot,
      duplicateSnapshot,
      slotSnapshot,
    ] = await Promise.all([
      transaction.get(shopRef),
      transaction.get(menuQuery),
      transaction.get(menuByIdRef),
      transaction.get(duplicateQuery),
      transaction.get(slotRef),
    ]);

    if (!shopSnapshot.exists || shopSnapshot.data()?.isWebPublished !== true) {
      throw new HttpsError("failed-precondition", "Shop is not published.");
    }

    if (!duplicateSnapshot.empty || slotSnapshot.exists) {
      throw new HttpsError(
          "already-exists",
          DUPLICATE_RESERVATION_MESSAGE,
      );
    }

    const menu = menuQuerySnapshot.empty ?
      menuByIdSnapshot.data() : menuQuerySnapshot.docs[0].data();
    if (!menu || menu.shopId !== shopId) {
      throw new HttpsError("not-found", "Menu was not found.");
    }

    const menuName = typeof menu.name === "string" && menu.name.trim() ?
      menu.name.trim() : menuId;
    const menuPrice = Number.isInteger(menu.price) ? menu.price : 0;
    const menuDuration = Number.isInteger(menu.duration) && menu.duration > 0 ?
      menu.duration : DEFAULT_MENU_DURATION_MINUTES;
    const end = Timestamp.fromMillis(
        reservationDateTime.toMillis() + menuDuration * 60 * 1000,
    );

    const reservation = {
      reservationId: reservationRef.id,
      shopId,
      menuId,
      customerName,
      customerPhone,
      customerEmail,
      reservationDateTime,
      status: "pending",
      source: "web",
      isNotified: false,
      createdAt: FieldValue.serverTimestamp(),
      name: customerName,
      phone: customerPhone,
      menu: menuName,
      price: menuPrice,
      duration: menuDuration,
      date: reservationDateTime,
      start: reservationDateTime,
      end,
    };

    transaction.create(reservationRef, reservation);
    transaction.create(slotRef, {
      reservationId: reservationRef.id,
      reservationDateTime,
      start: reservationDateTime,
      end,
      duration: menuDuration,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  return {reservationId: reservationRef.id};
}

module.exports = {
  DEFAULT_MENU_DURATION_MINUTES,
  DUPLICATE_RESERVATION_MESSAGE,
  createWebReservation,
  reservationSlotId,
};
