import 'package:flutter/material.dart';

import '../store/reservation_page.dart';
import '../customer/booking_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("SalonNote"),
        backgroundColor: Colors.white,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// 店舗用
            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationPage(),
                  ),
                );

              },
              child: const Text("店舗用"),
            ),

            const SizedBox(height: 40),

            /// お客様用
            ElevatedButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(),
                  ),
                );

              },
              child: const Text("お客様用"),
            ),

          ],
        ),
      ),
    );
  }
}