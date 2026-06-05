'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {buildNotificationBody, collectTokens, formatReservationDate} = require('./notification');

test('collectTokens deduplicates legacy and multi-device tokens', () => {
  assert.deepEqual(collectTokens({fcmToken: 'a', fcmTokens: ['a', 'b', '', null]}), ['a', 'b']);
});

test('formatReservationDate formats in Asia/Tokyo', () => {
  assert.equal(formatReservationDate(new Date('2026-06-10T01:00:00Z')), '2026/06/10 10:00');
});

test('buildNotificationBody contains customer, date, and menu on separate lines', () => {
  assert.equal(buildNotificationBody({
    customerName: '山田太郎',
    reservationDateTime: new Date('2026-06-10T01:00:00Z'),
    menu: 'カット',
  }), '山田太郎\n2026/06/10 10:00\nカット');
});
