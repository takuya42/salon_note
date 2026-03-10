import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_note/mypage/pages/mypage_page.dart';

class CustomerBookingPage extends StatefulWidget {
  final String? shopId;

  const CustomerBookingPage({super.key, this.shopId});



  @override
  State<CustomerBookingPage> createState() => _CustomerBookingPageState();
}
const primaryColor = Color(0xFFCBB8A9);
const darkBrown = Color(0xFF4E3B31);
const backgroundColor = Color(0xFFFCFCFC);

class _CustomerBookingPageState extends State<CustomerBookingPage> {
  int interval = 30;
  int openHour = 9;
  int closeHour = 21;

  List<int> closedDays = [];

  void _showBookingForm(DateTime date) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final confirmEmailController = TextEditingController();
    final phoneController = TextEditingController();

    String? selectedMenu;
    int selectedPrice = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 上バー
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                /// タイトル
                const Text(
                  "予約情報入力",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 6),

                /// サブタイトル
                Text(
                  "必要情報をご入力ください",
                  style: TextStyle(
                    color: darkBrown.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 28),

                /// 名前
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "名前",
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primaryColor.withOpacity(0.25),
                      ),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(14),
                      ),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// メール
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "メールアドレス",
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primaryColor.withOpacity(0.25),
                      ),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(14),
                      ),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// メール確認
                TextField(
                  controller: confirmEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "メールアドレス（確認）",
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primaryColor.withOpacity(0.25),
                      ),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(14),
                      ),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// 電話番号
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "電話番号",
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primaryColor.withOpacity(0.25),
                      ),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(14),
                      ),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// メニュー
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('shops')
                      .doc(widget.shopId)
                      .collection('menus')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final docs = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedMenu,

                      decoration: InputDecoration(
                        labelText: "メニュー選択",
                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(0.25),
                          ),
                        ),
                      ),

                      items: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return DropdownMenuItem<String>(
                          value: data['name'],
                          child: Text(
                            "${data['name']}（¥${data['price']}）",
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedMenu = value;

                          final selectedDoc = docs.firstWhere(
                                (doc) => (doc.data() as Map)['name'] == value,
                          );

                          selectedPrice = (selectedDoc.data() as Map)['price'];
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 28),

                /// ボタン
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: darkBrown,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final confirmEmail = confirmEmailController.text.trim();
                      final phone = phoneController.text.trim();

                      if (name.isEmpty) {
                        _showError("名前を入力してください");
                        return;
                      }

                      if (email.isEmpty) {
                        _showError("メールアドレスを入力してください");
                        return;
                      }

                      final emailRegex = RegExp(
                        r'^[^@]+@[^@]+\.[^@]+$',
                      );

                      if (!emailRegex.hasMatch(email)) {
                        _showError("正しいメールアドレスを入力してください");
                        return;
                      }

                      if (email != confirmEmail) {
                        _showError("メールアドレスが一致しません");
                        return;
                      }

                      if (phone.isEmpty) {
                        _showError("電話番号を入力してください");
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('shops')
                          .doc(widget.shopId)
                          .collection('reservations')
                          .add({
                        'name': name,
                        'email': email,
                        'phone': phone,
                        'start': date,
                        'end': date.add(const Duration(hours: 1)),
                        'createdAt':
                        FieldValue.serverTimestamp(),
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(
                        FirebaseAuth
                            .instance.currentUser!.uid,
                      )
                          .collection('customers')
                          .add({
                        'name': name,
                        'email': email,
                        'phone': phone,
                        'createdAt':
                        FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                    },
                    child: const Text(
                      "予約する",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> recentShops = [];
  List<Map<String, String>> myShops = [];

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    loadRecentShops();
    loadMyShops();
    _loadSettings();
  }

  /// 🔥 営業設定取得
  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('settings')
        .doc('business')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        openHour = data["openHour"] ?? 9;
        closeHour = data["closeHour"] ?? 21;
        interval = data["interval"] ?? 30;
        closedDays = List<int>.from(data["closedDays"] ?? []);
      });
    }
  }

  /// 🔥 店舗名
  Future<String> fetchShopName() async {
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .get();

    return (doc.data()?['name'] ?? "店舗名なし").toString();
  }

  /// 🔥 予約取得
  Stream<QuerySnapshot> reservationStream() {
    return FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('reservations')
        .snapshots();
  }

  /// 🔥 スロット生成（完全版）
  List<Appointment> buildSlots(List<QueryDocumentSnapshot> docs) {
    final booked = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Appointment(
        startTime: (data['start'] as Timestamp).toDate(),
        endTime: (data['end'] as Timestamp).toDate(),
      );
    }).toList();

    List<Appointment> slots = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final day = now.add(Duration(days: i));

      bool isClosedDay = closedDays.contains(day.weekday);

      DateTime start = DateTime(day.year, day.month, day.day, openHour);
      DateTime end = DateTime(day.year, day.month, day.day, closeHour);

      while (start.isBefore(end)) {
        DateTime slotEnd = start.add(Duration(minutes: interval));

        bool conflict = booked.any(
          (a) => start.isBefore(a.endTime) && slotEnd.isAfter(a.startTime),
        );

        String label;
        if (isClosedDay) {
          label = "休";
        } else if (conflict) {
          label = "×";
        } else {
          label = "○";
        }

        slots.add(
          Appointment(startTime: start, endTime: slotEnd, subject: label),
        );

        start = start.add(Duration(minutes: interval));
      }
    }

    return slots;
  }

  /// 🔥 予約
  Future<void> reserve(DateTime date) async {
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('reservations')
        .add({
          'name': '予約済み',
          'start': date,
          'end': date.add(Duration(minutes: interval)),
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (widget.shopId != null) {
      await saveRecentShop(widget.shopId!);
    }
  }

  /// 🔥 履歴保存
  Future<void> saveRecentShop(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('recent_shops') ?? [];
    list.remove(shopId);
    list.insert(0, shopId);
    if (list.length > 3) list = list.sublist(0, 3);
    await prefs.setStringList('recent_shops', list);
  }

  Future<void> clearRecentShops() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('recent_shops');

    setState(() {
      recentShops = [];
    });
  }

  /// 🔥 履歴
  Future<void> loadRecentShops() async {
    final prefs = await SharedPreferences.getInstance();
    recentShops = prefs.getStringList('recent_shops') ?? [];
    setState(() {});
  }

  /// 🔥 自店舗
  Future<void> loadMyShops() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('shops')
        .where('ownerId', isEqualTo: uid)
        .limit(3)
        .get();

    myShops = snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'name': (data['name'] ?? doc.id).toString()};
    }).toList();

    setState(() {});
  }

  void _showShopSelector() {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),

              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom:
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),

                child: SizedBox(
                  height: 620,

                  child: Column(
                    children: [

                      /// 上バー
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// タイトル
                      const Text(
                        "店舗を探す",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "近くのサロンを検索できます",
                        style: TextStyle(
                          color: darkBrown.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// 検索バー
                      TextField(
                        controller: searchController,

                        decoration: InputDecoration(
                          hintText: "店舗名で検索",

                          hintStyle: TextStyle(
                            color: darkBrown.withOpacity(0.5),
                          ),

                          prefixIcon: Icon(
                            Icons.search,
                            color: darkBrown.withOpacity(0.7),
                          ),

                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.2),
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),

                        onChanged: (_) {
                          setModalState(() {});
                        },
                      ),

                      const SizedBox(height: 24),

                      /// 検索結果
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('shops')
                              .snapshots(),

                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final keyword =
                            searchController.text.toLowerCase();

                            final docs =
                            snapshot.data!.docs.where((doc) {
                              final name = (doc['name'] ?? "")
                                  .toString()
                                  .toLowerCase();

                              return name.contains(keyword);
                            }).toList();

                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  "店舗が見つかりません",
                                  style: TextStyle(
                                    color:
                                    darkBrown.withOpacity(0.6),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: docs.length,

                              separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),

                              itemBuilder: (context, index) {
                                final doc = docs[index];

                                final data =
                                doc.data() as Map<String, dynamic>;

                                return Material(
                                  color: Colors.white,

                                  borderRadius:
                                  BorderRadius.circular(20),

                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius.circular(20),

                                    onTap: () async {
                                      await saveRecentShop(doc.id);

                                      Navigator.pop(context);

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CustomerBookingPage(
                                                shopId: doc.id,
                                              ),
                                        ),
                                      );
                                    },

                                    child: Container(
                                      padding:
                                      const EdgeInsets.all(18),

                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(20),

                                        border: Border.all(
                                          color: primaryColor
                                              .withOpacity(0.15),
                                        ),
                                      ),

                                      child: Row(
                                        children: [

                                          /// アイコン
                                          Container(
                                            width: 48,
                                            height: 48,

                                            decoration: BoxDecoration(
                                              color: primaryColor
                                                  .withOpacity(0.15),

                                              borderRadius:
                                              BorderRadius.circular(
                                                  14),
                                            ),

                                            child: const Icon(
                                              Icons.store,
                                              color: darkBrown,
                                            ),
                                          ),

                                          const SizedBox(width: 14),

                                          /// 店舗名
                                          Expanded(
                                            child: Text(
                                              data['name'] ?? '',

                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.bold,
                                                color: darkBrown,
                                              ),
                                            ),
                                          ),

                                          const Icon(
                                            Icons.chevron_right,
                                            color: darkBrown,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      /// 最近の店舗
                      if (recentShops.isNotEmpty) ...[
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              "最近の店舗",

                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: darkBrown,
                              ),
                            ),

                            TextButton(
                              onPressed: clearRecentShops,

                              child: const Text(
                                "履歴削除",
                                style: TextStyle(
                                  color: darkBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: darkBrown,
        title: widget.shopId == null
            ? const Text("店舗を選択してください")
            : FutureBuilder<String>(
                future: fetchShopName(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text("読み込み中...");
                  }

                  return Text(snapshot.data!);
                },
              ),

        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {
              _showShopSelector();
            },
          ),

          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyPage(isOwner: false)),
              );
            },
          ),
        ],
      ),
      body: widget.shopId == null
          ? Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: darkBrown,

              elevation: 0,

              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 18,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),

                side: BorderSide(
                  color: primaryColor.withOpacity(0.35),
                ),
              ),
            ),

            icon: Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.18),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.store,
                size: 20,
              ),
            ),

            label: const Padding(
              padding: EdgeInsets.only(left: 4),

              child: Text(
                "店舗を探す",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            onPressed: () {
              _showShopSelector();
            },
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: reservationStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final slots = buildSlots(snapshot.data!.docs);

          return Padding(
            padding: const EdgeInsets.all(12),

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),

                child: SfCalendar(
                  view: CalendarView.week,
                  dataSource: _DataSource(slots),
                  showCurrentTimeIndicator: false,

                  backgroundColor: backgroundColor,

                  todayHighlightColor: const Color(
                    0xFFD9B8A5,
                  ),

                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: Colors.white,

                    dayTextStyle: TextStyle(
                      color: darkBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),

                    dateTextStyle: TextStyle(
                      color: darkBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  headerStyle: CalendarHeaderStyle(
                    backgroundColor: backgroundColor,

                    textStyle: const TextStyle(
                      color: darkBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: openHour.toDouble() - 1,
                    endHour: closeHour.toDouble() + 1,
                    timeInterval: Duration(
                      minutes: interval,
                    ),
                    timeFormat: 'HH:mm',

                    timeTextStyle: TextStyle(
                      color: darkBrown.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),

                  appointmentBuilder: (
                      context,
                      details,
                      ) {
                    final appt =
                        details.appointments.first;

                    Color color;

                    if (appt.subject == "○") {
                      color = Colors.blue;
                    } else if (appt.subject == "休") {
                      color = Colors.grey;
                    } else {
                      color = Colors.red;
                    }

                    return Center(
                      child: Text(
                        appt.subject,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },

                  onTap: (details) {
                    if (details.appointments ==
                        null ||
                        details.appointments!
                            .isEmpty)
                      return;

                    final appt =
                        details.appointments!.first;

                    if (appt.subject == "×" ||
                        appt.subject == "休") {
                      return;
                    }

                    _showBookingForm(
                      appt.startTime,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}
