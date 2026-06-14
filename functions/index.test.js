const assert = require("node:assert/strict");
const test = require("node:test");

const {
  buildNotificationBody,
  formatReservationDate,
  getFcmTokens,
  redactFcmTokens,
  shouldNotifyWebReservation,
  summarizeSendResponses,
} = require("./notification");

test("builds the requested notification body", () => {
  const body = buildNotificationBody({
    customerName: "山田太郎",
    reservationDateTime: new Date("2026-06-10T01:00:00.000Z"),
    menu: "カット",
  });
  assert.equal(body, "山田太郎様 / 6月10日 10:00 / カット");
});

test("formats reservation dates in Asia/Tokyo", () => {
  assert.equal(
    formatReservationDate(new Date("2026-12-31T15:30:00.000Z")),
    "1月1日 00:30",
  );
});

test("deduplicates fcmToken and fcmTokens while preserving all devices", () => {
  assert.deepEqual(
    getFcmTokens({ fcmToken: "one", fcmTokens: ["old", "one", " two "] }),
    ["one", "old", "two"],
  );
});

test("uses all valid legacy tokens when fcmToken is absent", () => {
  assert.deepEqual(getFcmTokens({ fcmTokens: ["old", "", " latest "] }), [
    "old",
    "latest",
  ]);
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
  assert.equal(body, "佐藤花子様 / 6月10日 11:30 / カラー");
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
    this.id = path.split("/").at(-1);
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

class SuccessfulFakeFirestore {
  constructor({legacyMenu = false} = {}) {
    this.legacyMenu = legacyMenu;
    this.reads = [];
    this.writes = [];
  }

  collection(name) {
    return new FakeCollection(name, this);
  }

  async runTransaction(callback) {
    return callback({
      get: async (target) => {
        this.reads.push({path: target.path, filters: target.filters ?? []});
        if (target.path === "shops/shop-1") {
          return fakeSnapshot({exists: true, data: {isWebPublished: true}});
        }
        if (target.path === "menus/menu-1") {
          return this.legacyMenu ?
            fakeSnapshot() :
            fakeSnapshot({
              exists: true,
              data: {
                shopId: "shop-1",
                name: "カット",
                price: 5000,
                duration: 45,
              },
            });
        }
        if (target.path === "menus" &&
            target.filters.some(([field]) => field === "menuId")) {
          return fakeSnapshot({
            docs: [{
              shopId: "shop-1",
              name: "カット",
              price: 5000,
              duration: 45,
            }],
          });
        }
        return fakeSnapshot();
      },
      create: (reference, data) => {
        this.writes.push({path: reference.path, data});
      },
    });
  }
}

const validReservationRequest = {
  shopId: "shop-1",
  menuId: "menu-1",
  customerName: "山田太郎",
  customerPhone: "09012345678",
  customerEmail: "customer@example.com",
  reservationDateTimeMillis: 1781053200000,
};

test("builds a shop-scoped exact-start slot identifier", () => {
  const timestamp = {toMillis: () => 1781053200000};
  assert.equal(reservationSlotId(timestamp), "1781053200000");
});

test("rejects an existing reservation at the exact same time", async () => {
  await assert.rejects(
      createWebReservation(new DuplicateFakeFirestore(), {
        ...validReservationRequest,
      }),
      (error) => {
        assert.equal(error.code, "already-exists");
        assert.equal(error.message, DUPLICATE_RESERVATION_MESSAGE);
        return true;
      },
  );
});

test("creates reservation and slot without a composite menu query", async () => {
  const firestore = new SuccessfulFakeFirestore();

  const result = await createWebReservation(
      firestore,
      validReservationRequest,
  );

  assert.equal(result.reservationId, "generated-reservation-id");
  assert.equal(firestore.writes.length, 2);
  assert.equal(
      firestore.writes[0].path,
      "shops/shop-1/reservations/generated-reservation-id",
  );
  assert.equal(firestore.writes[0].data.source, "web");
  assert.equal(firestore.writes[0].data.shopId, "shop-1");
  assert.equal(firestore.writes[0].data.menuId, "menu-1");
  assert.equal(
      firestore.writes[1].path,
      "shops/shop-1/reservationSlots/1781053200000",
  );
  assert.equal(
      firestore.reads.some(({filters}) => filters.length > 1),
      false,
  );
});

test("supports a legacy menu document ID with a single-field query", async () => {
  const firestore = new SuccessfulFakeFirestore({legacyMenu: true});

  await createWebReservation(firestore, validReservationRequest);

  const menuQueryRead = firestore.reads.find(
      ({path, filters}) => path === "menus" && filters.length > 0,
  );
  assert.deepEqual(menuQueryRead.filters, [["menuId", "==", "menu-1"]]);
  assert.equal(firestore.writes.length, 2);
});
