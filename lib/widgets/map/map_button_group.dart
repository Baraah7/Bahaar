import 'package:flutter/material.dart';

class MapButtonGroup extends StatelessWidget {
  final List<Widget> buttons;

  const MapButtonGroup({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      children.add(buttons[i]);
      if (i < buttons.length - 1) {
        children.add(Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey.shade200,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
