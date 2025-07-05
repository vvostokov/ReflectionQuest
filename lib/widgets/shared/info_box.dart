// lib/widgets/shared/info_box.dart
import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color iconColor;

  const InfoBox({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline,
    this.iconColor = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}