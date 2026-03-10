import 'package:flutter/material.dart';
import 'reservation_tab.dart';
import 'tabs/sales_tab.dart';
import 'tabs/customer_tab.dart';

class ReservationPage extends StatelessWidget {
  const ReservationPage({super.key});

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 3,
      child: Scaffold(

        appBar: AppBar(
          title: const Text("店舗管理"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,

          bottom: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "予約"),
              Tab(text: "売上"),
              Tab(text: "顧客"),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            ReservationTab(),
            SalesTab(),
            CustomerTab(),
          ],
        ),
      ),
    );
  }
}