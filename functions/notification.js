function shouldNotifyWebReservation(reservation) {
  return reservation?.source === "web";
}

function getFcmTokens(user) {
  if (!user) return [];

  return [...new Set([
    normalizeToken(user.fcmToken),
    ...(Array.isArray(user.fcmTokens) ?
      user.fcmTokens.map(normalizeToken) :
      []),
  ].filter(Boolean))];
}

function normalizeToken(value) {
  return typeof value === "string" ? value.trim() : "";
}

function redactFcmTokens(tokens) {
  return tokens.map((token) =>
    token.length > 8 ? `...${token.slice(-8)}` : token);
}

function buildNotificationBody(reservation) {
  const customerName = stringOrFallback(
      reservation.customerName ?? reservation.name,
      "お名前未設定",
  );
  const menuName = stringOrFallback(
      reservation.menuName ?? reservation.menu,
      "メニュー未設定",
  );
  const date = reservation.reservationDateTime ??
    reservation.start ?? reservation.date;
  return `${customerName}様 / ${formatReservationDate(date)} / ${menuName}`;
}

function formatReservationDate(value) {
  if (value === null || value === undefined) return "日時未設定";
  const date = value?.toDate instanceof Function ? value.toDate() : new Date(value);
  if (Number.isNaN(date.getTime())) return "日時未設定";
  const parts = new Intl.DateTimeFormat("ja-JP", {
    timeZone: "Asia/Tokyo",
    month: "numeric",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const part = (type) => parts.find((item) => item.type === type)?.value ?? "";
  return `${part("month")}月${part("day")}日 ` +
    `${part("hour")}:${part("minute")}`;
}

function stringOrFallback(value, fallback) {
  return typeof value === "string" && value.trim().length > 0 ?
    value.trim() : fallback;
}

function summarizeSendResponses(response, tokens) {
  return response.responses.map((result, index) => ({
    index,
    success: result.success,
    token: redactFcmTokens([tokens[index] ?? ""])[0],
    code: result.error?.code ?? null,
    message: result.error?.message ?? null,
  }));
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
  redactFcmTokens,
  shouldNotifyWebReservation,
  summarizeSendResponses,
};
