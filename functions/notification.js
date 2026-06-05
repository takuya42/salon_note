'use strict';

const {DateTimeFormat} = Intl;

function collectTokens(userData = {}) {
  const tokens = [];
  if (typeof userData.fcmToken === 'string') tokens.push(userData.fcmToken);
  if (Array.isArray(userData.fcmTokens)) tokens.push(...userData.fcmTokens);
  return [...new Set(tokens.filter((token) => typeof token === 'string' && token.trim()))];
}

function formatReservationDate(value) {
  const date = value && typeof value.toDate === 'function' ? value.toDate() : new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const parts = Object.fromEntries(
    new DateTimeFormat('ja-JP', {
      timeZone: 'Asia/Tokyo', year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
    }).formatToParts(date).map(({type, value: part}) => [type, part]),
  );
  return `${parts.year}/${parts.month}/${parts.day} ${parts.hour}:${parts.minute}`;
}

function buildNotificationBody(reservation) {
  return [
    reservation.customerName || reservation.name || '',
    formatReservationDate(reservation.reservationDateTime || reservation.start || reservation.date),
    reservation.menuName || reservation.menu || reservation.menuId || '',
  ].join('\n');
}

module.exports = {buildNotificationBody, collectTokens, formatReservationDate};
