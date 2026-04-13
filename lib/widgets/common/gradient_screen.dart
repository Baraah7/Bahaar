import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bahaar/core/constants/app_colors.dart';

class GradientScreen extends StatelessWidget {
  final double expandedHeight;
  final Widget flexContent;       // content inside the flexible space (avatar, title, etc.)
  final Widget body;              // the white scrollable body
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const GradientScreen({
    super.key,
    this.expandedHeight = 200,
    required this.flexContent,
    required this.body,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: expandedHeight,
              pinned: true,
              automaticallyImplyLeading: automaticallyImplyLeading,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              actions: actions,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: flexContent,
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
