const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {
  buildNotificationBody,
  getFcmTokens,
  isInvalidToken,
  shouldNotifyWebReservation,
  summarizeSendFailures,
} = require("./notification");

initializeApp();

const REGION = "asia-northeast2";
const RESERVATIONS_ROUTE = "reservations";
const RESERVATIONS_CHANNEL = "reservations";

exports.notifyOwnerOfWebReservation = onDocumentCreated(
    {
      document: "shops/{shopId}/reservations/{reservationId}",
      region: REGION,
    },
    async (event) => {
      const reservation = event.data?.data();
      if (!shouldNotifyWebReservation(reservation)) {
        return;
      }

      const {shopId, reservationId} = event.params;
      const db = getFirestore();
      const shopSnapshot = await db.collection("shops").doc(shopId).get();
      const ownerIdValue = shopSnapshot.data()?.ownerId;
      const ownerId = typeof ownerIdValue === "string" ?
        ownerIdValue.trim() : "";
      if (!shopSnapshot.exists || !ownerId) {
        logger.warn("Reservation shop has no ownerId", {shopId, reservationId});
        return;
      }

      const userRef = db.collection("users").doc(ownerId);
      const userSnapshot = await userRef.get();
      if (!userSnapshot.exists) {
        logger.warn("Reservation owner user document does not exist", {
          shopId,
          reservationId,
          ownerId,
        });
        return;
      }

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
          notification: {channelId: RESERVATIONS_CHANNEL},
        },
        apns: {
          headers: {
            "apns-push-type": "alert",
            "apns-priority": "10",
          },
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
      const failures = summarizeSendFailures(response, tokens);
      failures.forEach((failure) => {
        logger.error("FCM delivery failed", {
          shopId,
          reservationId,
          ownerId,
          ...failure,
        });
      });

      const summary = {
        shopId,
        reservationId,
        ownerId,
        tokenCount: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
      if (response.failureCount > 0) {
        logger.warn("Web reservation notification completed with failures", summary);
      } else {
        logger.info("Sent web reservation notification", summary);
      }
    },
);
