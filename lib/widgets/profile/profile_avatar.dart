import 'package:flutter/material.dart';
import '../../models/registration/user.dart';

class ProfileAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const ProfileAvatar({super.key, required this.user, this.radius = 48});

  String get _initials {
    final first = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    final combined = '$first$last'.toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF004D63),
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.55,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
