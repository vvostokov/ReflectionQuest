import 'package:flutter/material.dart';

/// A centralized map of all supported icons. Using a map is more scalable
/// and maintainable than a large switch-case statement.
const Map<String, IconData> _iconMap = {
  'self_improvement': Icons.self_improvement,
  'book': Icons.book,
  'book_outlined': Icons.book_outlined,
  'edit': Icons.edit,
  'check_circle': Icons.check_circle,
  'star': Icons.star,
  'lightbulb': Icons.lightbulb,
  'local_drink_outlined': Icons.local_drink_outlined,
  'fitness_center_outlined': Icons.fitness_center_outlined,
  'shower_outlined': Icons.shower_outlined,
  'checklist_rtl_outlined': Icons.checklist_rtl_outlined,
  'format_quote': Icons.format_quote,
  'visibility_outlined': Icons.visibility_outlined,
  // Add new icons here
};

/// A reverse map for efficient reverse lookups (IconData -> String).
/// This is generated automatically from the primary `_iconMap`.
final Map<IconData, String> _reverseIconMap =
    _iconMap.map((key, value) => MapEntry(value, key));

/// Maps a string identifier to a const IconData instance.
/// This allows icons to be stored in a database/JSON without breaking
/// Flutter's icon tree shaking optimization in release mode.
IconData getIconFromString(String iconName) {
  return _iconMap[iconName] ?? Icons.help_outline; // A sensible default
}

/// Maps an IconData instance back to its string identifier.
/// Useful for saving user-selected icons to a database.
String getStringFromIcon(IconData icon) {
  // Note: This will not work for icons not present in `_iconMap`.
  // The default value should align with the one in `getIconFromString`.
  return _reverseIconMap[icon] ?? 'help_outline';
}