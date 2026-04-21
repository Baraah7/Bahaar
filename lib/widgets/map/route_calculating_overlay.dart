import 'package:flutter/material.dart';

class RouteCalculatingOverlay extends StatelessWidget {
  final String label;

  const RouteCalculatingOverlay({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(label, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
