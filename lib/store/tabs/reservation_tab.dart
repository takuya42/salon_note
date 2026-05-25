import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reservation_provider.dart';
import '../providers/customer_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../widgets/banner_ad_widget.dart';


const primaryColor = Color(0xFFCBB8A9);
const darkBrown = Color(0xFF4E3B31);
const backgroundColor = Color(0xFFFCFCFC);

String? get uid => FirebaseAuth.instance.currentUser?.uid;

class ReservationTab extends ConsumerStatefulWidget {
  const ReservationTab({super.key});

  @override
  ConsumerState<ReservationTab> createState() => _ReservationTabState();
}

class _ReservationTabState extends ConsumerState<ReservationTab> {
  String? shopId;

  String verticalText(String text) {
    return text.replaceAll(' ', '').split('').join('\n');
  }

  final CalendarController _calendarController = CalendarController();

  List<int> closedDays = [];
  int openHour = 10;
  int closeHour = 20;
  int interval = 30;

  @override
  void initState() {
    super.initState();
    _calendarController.view = CalendarView.week;
    loadShopId();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        closedDays = List<int>.from(data["closedDays"] ?? []);
        openHour = data["openHour"] ?? 10;
        closeHour = data["closeHour"] ?? 20;
        interval = data["interval"] ?? 30;
      });
    }
  }

  /// 🔥 ここに貼る（これ👇）
  Future<void> loadShopId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    shopId = doc.data()?['shopId'];
    await _loadSettings();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  List<TimeRegion> buildRegions() {
    List<TimeRegion> regions = [];
    DateTime now = DateTime.now();

    for (int i = -30; i < 30; i++) {
      final day = now.add(Duration(days: i));

      int prepStart = (openHour - 1).clamp(0, 23);
      int afterClose = (closeHour + 1).clamp(0, 24);

      if (closedDays.contains(day.weekday)) {
        regions.add(
          TimeRegion(
            startTime: DateTime(day.year, day.month, day.day, prepStart),
            endTime: DateTime(day.year, day.month, day.day, afterClose),
            enablePointerInteraction: false,
            color: darkBrown.withOpacity(0.12),
            text: "定休日",
          ),
        );
        continue;
      }

      regions.add(
        TimeRegion(
          startTime: DateTime(day.year, day.month, day.day, prepStart),
          endTime: DateTime(day.year, day.month, day.day, openHour),
          enablePointerInteraction: false,
          color: primaryColor.withOpacity(0.18),
          text: "準備中",
        ),
      );

      regions.add(
        TimeRegion(
          startTime: DateTime(day.year, day.month, day.day, closeHour),
          endTime: DateTime(day.year, day.month, day.day, afterClose),
          enablePointerInteraction: false,
          color: Colors.black.withOpacity(0.15),
          text: "準備中",
        ),
      );
    }

    return regions;
  }

  Future<bool> isConflict(DateTime start, DateTime end) async {
    if (shopId == null) return false;

    final snapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('reservations')
        .where('start', isLessThan: end)
        .where('end', isGreaterThan: start)
        .get();

    for (var doc in snapshot.docs) {
      DateTime existingStart = doc['start'].toDate();
      DateTime existingEnd = doc['end'].toDate();

      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  void addReservation(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final plan = userDoc.data()?['plan'] ?? 'free';
    if (shopId == null) return;

    final reservationSnapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('reservations')
        .limit(4)
        .get();

    final reservationCount = reservationSnapshot.docs.length;

    if (plan == 'free' && reservationCount >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("無料プランは予約3件までです")));
      return;
    }

    if (closedDays.contains(date.weekday)) return;
    if (date.hour < openHour || date.hour >= closeHour) return;
    if (uid == null) return;

    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController(); // ←追加🔥
    TextEditingController phoneController = TextEditingController();
    TextEditingController customMenuController = TextEditingController();

    String? selectedMenu;
    int selectedPrice = 0;
    Color selectedColor = Colors.orange;

    DateTime start = roundToInterval(date);
    DateTime end = start.add(const Duration(hours: 1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.82,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "予約追加",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                        ),

                        const SizedBox(height: 24),

                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "お客様の名前",
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

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

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

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

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

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('shops')
                              .doc(shopId)
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
                                  value: data['name']?.toString(),
                                  child: Text(
                                    "${data['name']}（¥${data['price']}）",
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  selectedMenu = value;

                                  final selectedDoc = docs.firstWhere(
                                    (doc) =>
                                        (doc.data()
                                                as Map<String, dynamic>)['name']
                                            .toString() ==
                                        value,
                                  );

                                  selectedPrice =
                                      (selectedDoc.data()
                                          as Map<String, dynamic>)['price'] ??
                                      0;
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: customMenuController,
                          decoration: InputDecoration(
                            labelText: "カスタムメニュー",
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
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            "料金：¥$selectedPrice",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              [
                                const Color(0xFFD46B8C),
                                const Color(0xFF5F9ED6),
                                const Color(0xFF67B567),
                                const Color(0xFFD9986A),
                                const Color(0xFF9D7AC8),
                              ].map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() => selectedColor = color);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    width: selectedColor == color ? 42 : 34,
                                    height: selectedColor == color ? 42 : 34,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedColor == color
                                            ? darkBrown
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 24),

                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: Colors.white,
                          title: const Text("開始時間"),
                          subtitle: Text(formatTime(start)),
                          trailing: const Icon(
                            Icons.access_time,
                            color: darkBrown,
                          ),
                          onTap: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (_) => SizedBox(
                                height: 250,
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  initialDateTime: start,
                                  use24hFormat: true,
                                  minuteInterval: interval,
                                  onDateTimeChanged: (DateTime newTime) {
                                    setModalState(() => start = newTime);
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: Colors.white,
                          title: const Text("終了時間"),
                          subtitle: Text(formatTime(end)),
                          trailing: const Icon(
                            Icons.access_time,
                            color: darkBrown,
                          ),
                          onTap: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (_) => SizedBox(
                                height: 250,
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  minuteInterval: interval,
                                  initialDateTime: end,
                                  use24hFormat: true,
                                  onDateTimeChanged: (t) {
                                    setModalState(() => end = t);
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

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
                              if (nameController.text.isEmpty) return;

                              final name = nameController.text;
                              final email = emailController.text;
                              final phone = phoneController.text;

                              String finalMenu;

                              if (customMenuController.text.isNotEmpty) {
                                finalMenu = customMenuController.text;
                              } else if (selectedMenu != null) {
                                finalMenu = selectedMenu!;
                              } else {
                                finalMenu = "未設定";
                              }

                              bool conflict = await isConflict(start, end);

                              if (conflict) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("この時間は予約できません")),
                                );
                                return;
                              }

                              final newReservation = await FirebaseFirestore.instance
                                  .collection('shops')
                                  .doc(shopId)
                                  .collection('reservations')
                                  .add({
                                    'name': nameController.text,
                                    'email': emailController.text,
                                    'phone': phoneController.text,
                                    'menu': finalMenu,
                                    'price': selectedPrice,
                                    'color': selectedColor.value,
                                    'start': start,
                                    'end': end,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });



                              await FirebaseAnalytics.instance.logEvent(
                                name: 'reservation_created',
                              );

                              ref.invalidate(reservationProvider);

                      Navigator.pop(context);

                              await ref
                                  .read(customerProvider.notifier)
                                  .addCustomerFull(
                                    name: name,
                                    email: email,
                                    phone: phone,
                                  );
                            },
                            child: const Text(
                              "予約追加",
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  void editReservation(Appointment appt) async {
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('reservations')
        .doc(appt.notes)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    TextEditingController nameController = TextEditingController(
      text: data['name'] ?? '',
    );

    TextEditingController emailController = TextEditingController(
      text: data['email'] ?? '',
    );

    TextEditingController phoneController = TextEditingController(
      text: data['phone'] ?? '',
    );

    TextEditingController customMenuController = TextEditingController();

    String? selectedMenu;
    int selectedPrice = 0;
    Color selectedColor = appt.color;

    DateTime start = roundToInterval(appt.startTime);
    DateTime end = roundToInterval(appt.endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("予約編集"),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "お客様の名前",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "メールアドレス",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "電話番号",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('shops')
                        .doc(shopId)
                        .collection('menus')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final docs = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: selectedMenu,
                        hint: const Text("メニュー選択"),
                        items: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: data['name'],
                            child: Text("${data['name']}（¥${data['price']}）"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedMenu = value;
                            final doc = docs.firstWhere(
                              (d) => (d.data() as Map)['name'] == value,
                            );
                            selectedPrice = (doc.data() as Map)['price'];
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: customMenuController,
                    decoration: const InputDecoration(
                      labelText: "カスタムメニュー（任意）",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("料金：¥$selectedPrice"),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        [
                          const Color(0xFFD46B8C), // ピンク
                          const Color(0xFF5F9ED6), // ブルー
                          const Color(0xFF67B567), // グリーン
                          const Color(0xFFD9986A), // オレンジ
                          const Color(0xFF9D7AC8), // パープル
                        ].map((color) {
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => selectedColor = color);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 20),

                  ListTile(
                    title: const Text("開始時間"),
                    subtitle: Text(formatTime(start)),
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (_) => SizedBox(
                          height: 250,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            minuteInterval: interval,
                            use24hFormat: true,
                            initialDateTime: start,
                            onDateTimeChanged: (t) {
                              setModalState(() => start = t);
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    title: const Text("終了時間"),
                    subtitle: Text(formatTime(end)),
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (_) => SizedBox(
                          height: 250,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            minuteInterval: interval,
                            use24hFormat: true,
                            initialDateTime: end,
                            onDateTimeChanged: (t) {
                              setModalState(() => end = t);
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      String finalMenu = customMenuController.text.isNotEmpty
                          ? customMenuController.text
                          : selectedMenu ?? "未設定";

                      await FirebaseFirestore.instance
                          .collection('shops')
                          .doc(shopId)
                          .collection('reservations')
                          .doc(appt.notes)
                          .update({
                            'name': nameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'menu': finalMenu,
                            'price': selectedPrice,
                            'color': selectedColor.value,
                            'start': start,
                            'end': end,
                          });

                      if (appt.notes != null) {

                      }

                      Navigator.pop(context);
                    },
                    child: const Text("更新"),
                  ),

                  /// ✅ これに変える
                  TextButton(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("削除確認"),
                            content: const Text("この予約を削除しますか？"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("キャンセル"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "削除",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (result == true) {
                        await FirebaseFirestore.instance
                            .collection('shops')
                            .doc(shopId)
                            .collection('reservations')
                            .doc(appt.notes)
                            .delete();

                        if (appt.notes != null) {
                        }

                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "削除",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReservationDetail(Appointment appt) async {
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('reservations')
        .doc(appt.notes)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "予約詳細",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Text("名前：${data['name'] ?? ''}"),
              Text("メール：${data['email'] ?? ''}"),
              Text("電話：${data['phone'] ?? ''}"),
              Text("メニュー：${data['menu'] ?? '未設定'}"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  editReservation(appt);
                },
                child: const Text("編集する"),
              ),

              TextButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("削除確認"),
                        content: const Text("この予約を削除しますか？"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("キャンセル"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "削除",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (result == true) {
                    await FirebaseFirestore.instance
                        .collection('shops')
                        .doc(shopId)
                        .collection('reservations')
                        .doc(appt.notes)
                        .delete();

                    Navigator.pop(context);
                  }
                },
                child: const Text("削除", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(reservationProvider);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final plan = data?['plan'] ?? 'free';

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: SfCalendar(
                  controller: _calendarController,
                  backgroundColor: backgroundColor,
                  dataSource: AppointmentDataSource(appointments),
                  showCurrentTimeIndicator: false,
                  todayHighlightColor: primaryColor,

                  selectionDecoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.25),
                    border: Border.all(
                      color: darkBrown.withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: const Color(0xFFF1E7E1),

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

                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: (openHour - 1).toDouble(),
                    endHour: (closeHour + 1).toDouble(),
                    timeInterval: Duration(minutes: interval),
                    timeFormat: 'H:mm',
                  ),

                  specialRegions: buildRegions(),

                  appointmentBuilder: (context, details) {
                    final Appointment appt = details.appointments.first;

                    return GestureDetector(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: appt.color,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.9),
                            width: 2,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            appt.subject,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },

                  onTap: (details) {
                    if (details.appointments != null &&
                        details.appointments!.isNotEmpty) {
                      final appt = details.appointments!.first;
                      _showReservationDetail(appt);
                    } else if (details.date != null) {
                      addReservation(details.date!);
                    }
                  },
                ),
              ),

              if (plan != 'pro') ...[
                const SizedBox(height: 8),

                const Text(
                  "無料プランをご利用中",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 6),

                const Center(child: BannerAdWidget()),

                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  DateTime roundToInterval(DateTime time) {
    int minute = (time.minute ~/ interval) * interval;
    return DateTime(time.year, time.month, time.day, time.hour, minute);
  }

  String formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
