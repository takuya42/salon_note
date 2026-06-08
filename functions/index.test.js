const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildNotificationBody,
  formatReservationDate,
  getFcmTokens,
  needsTokenNormalization,
  redactFcmTokens,
  shouldNotifyWebReservation,
  summarizeSendResponses,
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

test("uses only fcmToken when current and legacy token fields exist", () => {
  assert.deepEqual(
    getFcmTokens({ fcmToken: "one", fcmTokens: ["old", "one"] }),
    ["one"],
  );
});

test("uses the last valid legacy token when fcmToken is absent", () => {
  assert.deepEqual(getFcmTokens({ fcmTokens: ["old", "", " latest "] }), [
    "latest",
  ]);
});

test("detects token fields that need normalization", () => {
  assert.equal(
    needsTokenNormalization(
      {
        fcmToken: "latest",
        fcmTokens: ["old", "latest"],
      },
      "latest",
    ),
    true,
  );
  assert.equal(
    needsTokenNormalization(
      {
        fcmToken: "latest",
        fcmTokens: ["latest"],
      },
      "latest",
    ),
    false,
  );
});

test("only web reservations trigger owner notifications", () => {
  assert.equal(shouldNotifyWebReservation({ source: "web" }), true);
  assert.equal(shouldNotifyWebReservation({ source: "app" }), false);
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

test("summarizes every multicast response without logging full tokens", () => {
  const error = {
    code: "messaging/third-party-auth-error",
    message: "APNs rejected",
  };
  const responses = summarizeSendResponses(
    { responses: [{ success: true }, { success: false, error }] },
    ["first-token", "sensitive-second-token"],
  );

  assert.deepEqual(responses, [
    {
      index: 0,
      success: true,
      token: "...st-token",
      code: null,
      message: null,
    },
    {
      index: 1,
      success: false,
      token: "...nd-token",
      code: "messaging/third-party-auth-error",
      message: "APNs rejected",
    },
  ]);
  assert.deepEqual(redactFcmTokens(["sensitive-second-token"]), [
    "...nd-token",
  ]);
});
