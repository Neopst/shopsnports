import 'package:flutter/material.dart';
import 'package:shopsnports/styles/colors.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.location_on, color: AppColors.primaryColor, size: 20),
        SizedBox(width: 6),
        Text('Lagos, Nigeria'),
      ],
    );
  }
}
