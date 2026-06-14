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
    async (request) => {
      logger.info("createWebReservation callable received", {
        requestData: request.data ?? null,
      });
      try {
        const result = await createWebReservation(db, request.data);
        logger.info("createWebReservation callable succeeded", result);
        return result;
      } catch (error) {
        logger.error("createWebReservation callable failed", {
          requestData: request.data ?? null,
          code: error?.code ?? null,
          errorMessage: error?.message ?? String(error),
          details: error?.details ?? null,
          stack: error?.stack ?? null,
          permissionDenied: error?.code === "permission-denied" ||
            error?.code === 7,
          failedPrecondition: error?.code === "failed-precondition" ||
            error?.code === 9,
          invalidArgument: error?.code === "invalid-argument" ||
            error?.code === 3,
          alreadyExists: error?.code === "already-exists" ||
            error?.code === 6,
        });
        throw error;
      }
    },
);

exports.notifyOwnerOfWebReservation = onDocumentCreated(
    {
      document: "shops/{shopId}/reservations/{reservationId}",
      region: REGION,
    },
    async (event) => {
      const {shopId, reservationId} = event.params;
      const reservation = event.data?.data();
      if (!shouldNotifyWebReservation(reservation)) {
        logger.debug("Skipped non-web reservation notification", {
          shopId,
          reservationId,
          source: reservation?.source ?? null,
        });
        return;
      }

      try {
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
            successCount: 0,
            failureCount: 0,
          });
          return;
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
          const log = deliveryResponse.success ? logger.info : logger.error;
          log("FCM/APNs delivery response", {
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
          const invalidTokenSet = new Set(invalidTokens);
          const validTokens = tokens.filter((token) => !invalidTokenSet.has(token));
          const tokenUpdate = {fcmTokens: validTokens};
          if (invalidTokenSet.has(user.fcmToken)) {
            tokenUpdate.fcmToken = validTokens[0] ?? FieldValue.delete();
          }
          await userRef.set(tokenUpdate, {merge: true});
          logger.warn("Removed invalid reservation owner FCM tokens", {
            ...deliveryContext,
            invalidTokens: redactFcmTokens(invalidTokens),
            remainingTokenCount: validTokens.length,
          });
        }

        const summary = {
          ...deliveryContext,
          successCount: response.successCount,
          failureCount: response.failureCount,
        };
        logger.info("Web reservation notification result", summary);

        if (response.failureCount > 0) {
          logger.error("FCM/APNs delivery failed", {
            ...summary,
            responses: deliveryResponses,
          });
        } else {
          logger.info("Sent web reservation notification", summary);
        }
      } catch (error) {
        logger.error("Web reservation notification handler failed", {
          shopId,
          reservationId,
          code: error?.code ?? null,
          message: error?.message ?? String(error),
          stack: error?.stack ?? null,
          successCount: 0,
          failureCount: 1,
        });
        throw error;
      }
    },
);
