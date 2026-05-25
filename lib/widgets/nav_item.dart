import 'package:flutter/material.dart';
import 'package:shopsnports/styles/colors.dart';

/// Reusable small navigation item used by the bottom navigation layout.
class NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.grey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Flexible(
                child: Text(label,
                    style: TextStyle(fontSize: 9, color: color),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
