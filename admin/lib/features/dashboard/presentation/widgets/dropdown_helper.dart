// File: C:/projects/admin_dashboard/lib/features/dashboard/presentation/widgets/dropdown_helper.dart

import 'package:flutter/material.dart';

void showDropdownMenu({
  required BuildContext context,
  required GlobalKey iconKey,
  required Widget menu,
}) {
  final overlay = Overlay.of(context);
  final renderBox = iconKey.currentContext!.findRenderObject() as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);

  final screenWidth = MediaQuery.of(context).size.width;
  const double menuWidth = 300.0; // adjust if your menus are wider/narrower

  double left = position.dx;

  // ✅ Prevent overflow on the right
  if (left + menuWidth > screenWidth) {
    left = screenWidth - menuWidth - 16; // keep 16px margin
  }

  // ✅ Prevent overflow on the left
  if (left < 16) {
    left = 16;
  }

  late OverlayEntry entry;
  late OverlayEntry barrier;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: position.dy + renderBox.size.height,
      left: left,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: menuWidth),
          child: menu,
        ),
      ),
    ),
  );

  barrier = OverlayEntry(
    builder: (context) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        entry.remove();
        barrier.remove();
      },
    ),
  );

  overlay.insert(barrier);
  overlay.insert(entry);
}
