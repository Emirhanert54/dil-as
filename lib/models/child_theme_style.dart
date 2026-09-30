import 'package:flutter/material.dart';

class ChildThemeStyle {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final List<Color> gradient;
  final Color background;

  const ChildThemeStyle({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.gradient,
    required this.background,
  });
}