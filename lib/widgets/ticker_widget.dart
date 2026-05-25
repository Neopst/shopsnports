import 'package:flutter/material.dart';
import 'package:shopsnports/styles/colors.dart';

class TickerWidget extends StatelessWidget {
  const TickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accentColor,
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          SizedBox(width: 20),
          Text('🚚 Free shipping on orders over ₦10,000',
              style: TextStyle(color: Colors.white)),
          SizedBox(width: 40),
          Text('🔥 Flash Sale: 20% off Electronics',
              style: TextStyle(color: Colors.white)),
          SizedBox(width: 40),
          Text('🛒 New arrivals in Fashion',
              style: TextStyle(color: Colors.white)),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}
