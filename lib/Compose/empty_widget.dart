import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final String? imagePath;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath ?? 'assets/img/empty.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          title,
          if (subtitle != null)
            subtitle!
        ],
      ),
    );
  }
}

