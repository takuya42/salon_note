function getFcmTokens(user) {
  if (!user) return [];
  const tokens = new Set();
  if (typeof user.fcmToken === "string" && user.fcmToken.trim().length > 0) {
    tokens.add(user.fcmToken.trim());
  }
  if (Array.isArray(user.fcmTokens)) {
    for (const token of user.fcmTokens) {
      if (typeof token === "string" && token.trim().length > 0) {
        tokens.add(token.trim());
      }
    }
  }
  return [...tokens];
}

function buildNotificationBody(reservation) {
  const customerName = stringOrFallback(
      reservation.customerName ?? reservation.name,
      "お名前未設定",
  );
  const menuName = stringOrFallback(reservation.menu, "メニュー未設定");
  const date = reservation.reservationDateTime ??
    reservation.start ?? reservation.date;
  return `${customerName}\n${formatReservationDate(date)}\n${menuName}`;
}

function formatReservationDate(value) {
  if (value === null || value === undefined) return "日時未設定";
  const date = value?.toDate instanceof Function ? value.toDate() : new Date(value);
  if (Number.isNaN(date.getTime())) return "日時未設定";
  const parts = new Intl.DateTimeFormat("ja-JP", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const part = (type) => parts.find((item) => item.type === type)?.value ?? "";
  return `${part("year")}/${part("month")}/${part("day")} ` +
    `${part("hour")}:${part("minute")}`;
}

function stringOrFallback(value, fallback) {
  return typeof value === "string" && value.trim().length > 0 ?
    value.trim() : fallback;
}

function isInvalidToken(error) {
  return [
    "messaging/invalid-registration-token",
    "messaging/registration-token-not-registered",
  ].includes(error?.code);
}

module.exports = {
  buildNotificationBody,
  formatReservationDate,
  getFcmTokens,
  isInvalidToken,
};
