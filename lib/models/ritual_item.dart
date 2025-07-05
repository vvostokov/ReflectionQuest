// lib/models/ritual_item.dart
import 'package:flutter/widgets.dart';
import 'package:my_reflection_app/helpers/icon_helper.dart';

enum RitualLevel { easy, medium, hard }

class RitualItem {
  final String id;
  final String text;
  final String iconName;

  IconData get icon => getIconFromString(iconName);

  const RitualItem({required this.id, required this.text, required this.iconName});

  // Методы для сериализации/десериализации
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'iconName': iconName,
      };

  factory RitualItem.fromJson(Map<String, dynamic> json) {
    return RitualItem(
      id: json['id'],
      text: json['text'],
      iconName: json['iconName'] as String? ?? 'help_outline',
    );
  }
}