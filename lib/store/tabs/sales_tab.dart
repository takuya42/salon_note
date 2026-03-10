import 'package:flutter/material.dart';

class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [

          Text(
            "今日の売上",
            style: TextStyle(fontSize: 18),
          ),

          SizedBox(height: 10),

          Text(
            "¥0",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}