const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall} = require("firebase-functions/v2/https");
const {createWebReservation} = require("./booking");
const {
  buildNotificationBody,
  getFcmTokens,
  isInvalidToken,
  needsTokenNormalization,
  redactFcmTokens,
  shouldNotifyWebReservation,
  summarizeSendResponses,
} = require("./notification");

const app = initializeApp();
const db = getFirestore(app);
const messaging = getMessaging(app);

const REGION = "asia-northeast2";
const RESERVATIONS_ROUTE = "reservations";
const RESERVATIONS_CHANNEL = "reservations";

exports.createWebReservation = onCall(
    {region: REGION},
    async (request) => createWebReservation(db, request.data),
);

exports.notifyOwnerOfWebReservation = onDocumentCreated(
    {
      document: "shops/{shopId}/reservations/{reservationId}",
      region: REGION,
    },
    async (event) => {
      const reservation = event.data?.data();
      if (!shouldNotifyWebReservation(reservation)) return;

      const {shopId, reservationId} = event.params;
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

      const user = userSnapshot.data();
      const tokens = getFcmTokens(user);
      if (tokens.length === 0) {
        logger.info("Reservation owner has no FCM token", {
          shopId,
          reservationId,
          ownerId,
        });
        return;
      }

      if (needsTokenNormalization(user, tokens[0])) {
        await userRef.set({
          fcmToken: tokens[0],
          fcmTokens: [tokens[0]],
        }, {merge: true});
        logger.info("Normalized reservation owner FCM tokens", {
          shopId,
          reservationId,
          ownerId,
          tokenCount: 1,
          tokens: redactFcmTokens(tokens),
        });
      }

      const deliveryContext = {
        shopId,
        reservationId,
        ownerId,
        tokenCount: tokens.length,
        tokens: redactFcmTokens(tokens),
      };
      logger.info("Sending web reservation notification", deliveryContext);

      const response = await messaging.sendEachForMulticast({
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

      const deliveryResponses = summarizeSendResponses(response, tokens);
      deliveryResponses.forEach((deliveryResponse) => {
        logger.info("FCM delivery response", {
          shopId,
          reservationId,
          ownerId,
          ...deliveryResponse,
        });
      });

      const invalidTokens = response.responses
          .map((result, index) =>
            isInvalidToken(result.error) ? tokens[index] : null)
          .filter(Boolean);
      if (invalidTokens.length > 0) {
        await userRef.update({
          fcmToken: FieldValue.delete(),
          fcmTokens: [],
        });
        logger.warn("Removed invalid reservation owner FCM token", {
          ...deliveryContext,
          invalidTokens: redactFcmTokens(invalidTokens),
        });
      }

      const summary = {
        ...deliveryContext,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
      logger.info("Web reservation notification result", summary);

      if (response.failureCount > 0) {
        logger.error("FCM delivery failed", {
          ...summary,
          responses: deliveryResponses,
        });
      } else {
        logger.info("Sent web reservation notification", summary);
      }
    },
);
