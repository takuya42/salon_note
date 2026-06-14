const {FieldValue, Timestamp} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions");
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

function firestoreErrorCode(error) {
  const code = error?.code;
  const codes = {
    3: "invalid-argument",
    6: "already-exists",
    7: "permission-denied",
    9: "failed-precondition",
  };
  return codes[code] ?? code ?? "internal";
}

async function getMenuSnapshot(transaction, menusRef, menuId) {
  const menuByIdSnapshot = await transaction.get(menusRef.doc(menuId));
  if (menuByIdSnapshot.exists) {
    return menuByIdSnapshot;
  }

  // Legacy menu documents may use an auto-generated document ID. Query only
  // menuId here so reservation creation never depends on a composite index.
  const legacyMenuSnapshot = await transaction.get(
      menusRef.where("menuId", "==", menuId).limit(1),
  );
  return legacyMenuSnapshot.empty ? null : legacyMenuSnapshot.docs[0];
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
  const duplicateQuery = reservationsRef
      .where("reservationDateTime", "==", reservationDateTime)
      .limit(1);

  logger.info("Validated web reservation request", {
    shopId,
    menuId,
    customerName,
    customerEmail,
    reservationDateTime: reservationDateTime.toDate().toISOString(),
    requestData: input,
  });

  try {
    await db.runTransaction(async (transaction) => {
      const [
        shopSnapshot,
        menuSnapshot,
        duplicateSnapshot,
        slotSnapshot,
      ] = await Promise.all([
        transaction.get(shopRef),
        getMenuSnapshot(transaction, menusRef, menuId),
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

      const menu = menuSnapshot?.data();
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
      const reservationSlot = {
        reservationId: reservationRef.id,
        reservationDateTime,
        start: reservationDateTime,
        end,
        duration: menuDuration,
        createdAt: FieldValue.serverTimestamp(),
      };

      logger.info("Writing web reservation transaction", {
        reservationPath: reservationRef.path,
        reservationData: reservation,
        reservationSlotPath: slotRef.path,
        reservationSlotData: reservationSlot,
      });
      transaction.create(reservationRef, reservation);
      transaction.create(slotRef, reservationSlot);
    });
  } catch (error) {
    const code = firestoreErrorCode(error);
    logger.error("Firestore web reservation write failed", {
      shopId,
      menuId,
      customerName,
      customerEmail,
      reservationDateTime: reservationDateTime.toDate().toISOString(),
      reservationPath: reservationRef.path,
      reservationSlotPath: slotRef.path,
      code,
      originalCode: error?.code ?? null,
      errorMessage: error?.message ?? String(error),
      stack: error?.stack ?? null,
      permissionDenied: code === "permission-denied",
      failedPrecondition: code === "failed-precondition",
      invalidArgument: code === "invalid-argument",
      alreadyExists: code === "already-exists",
    });
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
        ["permission-denied", "failed-precondition", "invalid-argument",
          "already-exists"].includes(code) ? code : "internal",
        "Failed to save reservation.",
        {originalCode: error?.code ?? null},
    );
  }

  return {reservationId: reservationRef.id};
}

module.exports = {
  DEFAULT_MENU_DURATION_MINUTES,
  DUPLICATE_RESERVATION_MESSAGE,
  createWebReservation,
  reservationSlotId,
};
