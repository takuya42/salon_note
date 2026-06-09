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

const {
  DUPLICATE_RESERVATION_MESSAGE,
  createWebReservation,
  reservationSlotId,
} = require("./booking");

class FakeReference {
  constructor(path, database) {
    this.path = path;
    this.database = database;
  }

  collection(name) {
    return new FakeCollection(`${this.path}/${name}`, this.database);
  }
}

class FakeCollection extends FakeReference {
  doc(id = "generated-reservation-id") {
    return new FakeReference(`${this.path}/${id}`, this.database);
  }

  where(field, operator, value) {
    return new FakeQuery(this.path, this.database, [[field, operator, value]]);
  }
}

class FakeQuery {
  constructor(path, database, filters) {
    this.path = path;
    this.database = database;
    this.filters = filters;
  }

  where(field, operator, value) {
    return new FakeQuery(
        this.path,
        this.database,
        [...this.filters, [field, operator, value]],
    );
  }

  limit() {
    return this;
  }
}

function fakeSnapshot({exists = false, data, docs = []} = {}) {
  return {
    exists,
    empty: docs.length === 0,
    data: () => data,
    docs: docs.map((value) => ({data: () => value})),
  };
}

class DuplicateFakeFirestore {
  collection(name) {
    return new FakeCollection(name, this);
  }

  async runTransaction(callback) {
    return callback({
      get: async (target) => {
        if (target.path === "shops/shop-1") {
          return fakeSnapshot({exists: true, data: {isWebPublished: true}});
        }
        if (target.path === "menus/menu-1") {
          return fakeSnapshot({
            exists: true,
            data: {shopId: "shop-1", duration: 30},
          });
        }
        if (target.path === "shops/shop-1/reservations") {
          return fakeSnapshot({docs: [{reservationId: "existing"}]});
        }
        return fakeSnapshot();
      },
      create: () => assert.fail("duplicate reservation must not be written"),
    });
  }
}

test("builds a shop-scoped exact-start slot identifier", () => {
  const timestamp = {toMillis: () => 1781053200000};
  assert.equal(reservationSlotId(timestamp), "1781053200000");
});

test("rejects an existing reservation at the exact same time", async () => {
  await assert.rejects(
      createWebReservation(new DuplicateFakeFirestore(), {
        shopId: "shop-1",
        menuId: "menu-1",
        customerName: "山田太郎",
        customerPhone: "09012345678",
        customerEmail: "customer@example.com",
        reservationDateTimeMillis: 1781053200000,
      }),
      (error) => {
        assert.equal(error.code, "already-exists");
        assert.equal(error.message, DUPLICATE_RESERVATION_MESSAGE);
        return true;
      },
  );
});
