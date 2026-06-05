const assert = require("node:assert/strict");
const test = require("node:test");

const {buildNotificationBody, formatReservationDate, getFcmTokens} =
  require("./notification");

test("builds the requested three-line notification body", () => {
  const body = buildNotificationBody({
    customerName: "山田太郎",
    reservationDateTime: new Date("2026-06-10T01:00:00.000Z"),
    menu: "カット",
  });
  assert.equal(body, "山田太郎\n2026/06/10 10:00\nカット");
});

test("formats reservation dates in Asia/Tokyo", () => {
  assert.equal(
      formatReservationDate(new Date("2026-12-31T15:30:00.000Z")),
      "2027/01/01 00:30",
  );
});

test("deduplicates current and legacy token fields", () => {
  assert.deepEqual(
      getFcmTokens({fcmToken: "one", fcmTokens: ["one", "two", ""]}),
      ["one", "two"],
  );
});
