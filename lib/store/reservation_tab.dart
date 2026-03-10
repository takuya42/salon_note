import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'reservation_controller.dart';

class ReservationTab extends StatefulWidget {
  const ReservationTab({super.key});

  @override
  State<ReservationTab> createState() => _ReservationTabState();
}

class _ReservationTabState extends State<ReservationTab> {

  final CalendarController calendarController = CalendarController();
  final ReservationController controller = ReservationController();

  /// 予約追加UI
  void addReservationUI(DateTime date) {

    TextEditingController nameController = TextEditingController();

    DateTime start = controller.round15(date);
    DateTime end = start.add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text("予約追加",
                  style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "お客様の名前",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {

                  if(nameController.text.isEmpty) return;

                  setState(() {

                    controller.addReservation(
                      name: nameController.text,
                      start: start,
                      end: end,
                    );

                  });

                  Navigator.pop(context);
                },
                child: const Text("予約追加"),
              ),

              const SizedBox(height: 20),

            ],
          ),
        );

      },
    );

  }

  @override
  Widget build(BuildContext context) {

    return SfCalendar(

      controller: calendarController,

      view: CalendarView.week,

      dataSource: AppointmentDataSource(controller.appointments),

      allowDragAndDrop: true,
      allowAppointmentResize: true,

      showNavigationArrow: true,

      todayHighlightColor: Colors.orange,

      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 9,
        endHour: 21,
        timeInterval: Duration(minutes: 15),
        timeFormat: 'H:mm',
      ),

      onTap: (details){

        if(details.targetElement == CalendarElement.calendarCell){

          if(details.date != null){
            addReservationUI(details.date!);
          }

        }

      },

    );

  }

}

class AppointmentDataSource extends CalendarDataSource {

  AppointmentDataSource(List<Appointment> source){

    appointments = source;

  }

}