import 'package:flutter/material.dart';

/// Maps a string identifier to a const IconData instance.
/// This allows icons to be stored in a database/JSON without breaking
/// Flutter's icon tree shaking optimization in release mode.
IconData getIconFromString(String iconName) {
  switch (iconName) {
    case 'self_improvement':
      return Icons.self_improvement;
    case 'book':
      return Icons.book;
    case 'edit':
      return Icons.edit;
    case 'check_circle':
      return Icons.check_circle;
    case 'star':
      return Icons.star;
    case 'lightbulb':
      return Icons.lightbulb;
    // Add more mappings here as you add more icons
    default:
      return Icons.help_outline; // A sensible default
  }
}

// You might also want a function to go the other way if you allow users to pick icons.
// String getStringFromIcon(IconData icon) { ... }

