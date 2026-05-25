import 'package:flutter/material.dart';

class BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onPressed;
  final bool active;

  const BadgeIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
    required this.onPressed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active ? color : Colors.grey;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
