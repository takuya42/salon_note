'use strict';

const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {buildNotificationBody, collectTokens} = require('./notification');

initializeApp();

exports.notifyOwnerOfWebReservation = onDocumentCreated(
  {document: 'shops/{shopId}/reservations/{reservationId}', region: 'asia-northeast2'},
  async (event) => {
    const reservation = event.data?.data();
    if (!reservation || reservation.source !== 'web') return;

    const db = getFirestore();
    const shop = await db.doc(`shops/${event.params.shopId}`).get();
    const ownerId = shop.get('ownerId');
    if (typeof ownerId !== 'string' || !ownerId) return;

    const userRef = db.doc(`users/${ownerId}`);
    const user = await userRef.get();
    const tokens = collectTokens(user.data());
    if (!tokens.length) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: '新しい予約が入りました',
        body: buildNotificationBody(reservation),
      },
      data: {
        type: 'reservation',
        shopId: event.params.shopId,
        reservationId: event.params.reservationId,
      },
      android: {
        priority: 'high',
        notification: {channelId: 'reservations'},
      },
      apns: {
        payload: {aps: {sound: 'default'}},
      },
    });

    const invalidTokens = [];
    response.responses.forEach((result, index) => {
      if (result.success) return;
      if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(result.error?.code)) {
        invalidTokens.push(tokens[index]);
      }
    });
    if (invalidTokens.length) {
      await userRef.set({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
        ...(invalidTokens.includes(user.get('fcmToken')) ? {fcmToken: FieldValue.delete()} : {}),
      }, {merge: true});
    }
  },
);
