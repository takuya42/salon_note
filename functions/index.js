const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {
  buildNotificationBody,
  getFcmTokens,
  isInvalidToken,
} = require("./notification");

initializeApp();

const REGION = "asia-northeast2";
const RESERVATIONS_ROUTE = "reservations";

exports.notifyOwnerOfWebReservation = onDocumentCreated(
    {
      document: "shops/{shopId}/reservations/{reservationId}",
      region: REGION,
    },
    async (event) => {
      const reservation = event.data?.data();
      if (!reservation || reservation.source !== "web") {
        return;
      }

      const {shopId, reservationId} = event.params;
      const db = getFirestore();
      const shopSnapshot = await db.collection("shops").doc(shopId).get();
      const ownerId = shopSnapshot.get("ownerId");
      if (typeof ownerId !== "string" || ownerId.length === 0) {
        logger.warn("Reservation shop has no ownerId", {shopId, reservationId});
        return;
      }

      const userRef = db.collection("users").doc(ownerId);
      const userSnapshot = await userRef.get();
      const tokens = getFcmTokens(userSnapshot.data());
      if (tokens.length === 0) {
        logger.info("Reservation owner has no FCM token", {
          shopId,
          reservationId,
          ownerId,
        });
        return;
      }

      const response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "新しい予約が入りました",
          body: buildNotificationBody(reservation),
        },
        data: {
          route: RESERVATIONS_ROUTE,
          shopId,
          reservationId,
        },
        android: {
          priority: "high",
          notification: {channelId: "reservations"},
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      const invalidTokens = response.responses
          .map((result, index) =>
            isInvalidToken(result.error) ? tokens[index] : null)
          .filter(Boolean);
      if (invalidTokens.length > 0) {
        const updates = {fcmTokens: FieldValue.arrayRemove(...invalidTokens)};
        if (invalidTokens.includes(userSnapshot.get("fcmToken"))) {
          updates.fcmToken = FieldValue.delete();
        }
        await userRef.update(updates);
      }

      logger.info("Sent web reservation notification", {
        shopId,
        reservationId,
        ownerId,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    },
);
