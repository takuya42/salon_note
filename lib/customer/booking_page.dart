import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  final List<Appointment> appointments = [
    Appointment(
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 3)),
      subject: "予約済",
      color: Colors.red,
    ),
  ];

  /// 予約する
  void reserve(DateTime date) {

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("予約確認"),
          content: Text("${date.hour}:${date.minute.toString().padLeft(2, '0')} を予約しますか？"),

          actions: [

            TextButton(
              child: const Text("キャンセル"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            TextButton(
              child: const Text("予約する"),
              onPressed: () {

                setState(() {

                  appointments.add(
                    Appointment(
                      startTime: date,
                      endTime: date.add(const Duration(minutes: 60)),
                      subject: "予約済",
                      color: Colors.red,
                    ),
                  );

                });

                Navigator.pop(context);
              },
            ),

          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("予約"),
      ),

      body: SfCalendar(

        view: CalendarView.day,

        dataSource: MeetingDataSource(appointments),

        initialDisplayDate: DateTime.now(),

        todayHighlightColor: Colors.orange,

        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 9,
          endHour: 21,
          timeInterval: Duration(minutes: 30),
        ),

        /// 空きタップ
        onTap: (details) {

          if (details.date != null) {
            reserve(details.date!);
          }

        },
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {

  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }

}