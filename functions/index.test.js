const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildNotificationBody,
  formatReservationDate,
  getFcmTokens,
  shouldNotifyWebReservation,
} = require("./notification");

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

test("only web reservations trigger owner notifications", () => {
  assert.equal(shouldNotifyWebReservation({source: "web"}), true);
  assert.equal(shouldNotifyWebReservation({source: "app"}), false);
  assert.equal(shouldNotifyWebReservation({}), false);
  assert.equal(shouldNotifyWebReservation(null), false);
});

test("uses an explicit menu name when the reservation provides one", () => {
  const body = buildNotificationBody({
    customerName: "佐藤花子",
    reservationDateTime: new Date("2026-06-10T02:30:00.000Z"),
    menuName: "カラー",
    menu: "legacy-menu-id",
  });
  assert.equal(body, "佐藤花子\n2026/06/10 11:30\nカラー");
});
