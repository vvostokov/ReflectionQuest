import 'package:flutter/material.dart';

class MemoryCardModel {
  final IconData icon;
  bool isFlipped;
  bool isMatched;

  MemoryCardModel({
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });
}