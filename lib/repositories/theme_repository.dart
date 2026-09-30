import 'package:flutter/material.dart';
import '../models/child_theme_style.dart';

class ThemeRepository {
  static const List<ChildThemeStyle> themes = [
    ChildThemeStyle(
      id: "space",
      title: "Uzay Teması",
      emoji: "🚀",
      description: "Mor ve mavi uzay havası.",
      gradient: [Color(0xFF6C63FF), Color(0xFF8E2DE2)],
      background: Color(0xFFF0F2F5),
    ),
    ChildThemeStyle(
      id: "rainbow",
      title: "Gökkuşağı Teması",
      emoji: "🌈",
      description: "Renkli ve neşeli görünüm.",
      gradient: [Color(0xFFFF8A65), Color(0xFFAB47BC)],
      background: Color(0xFFFFF7F9),
    ),
    ChildThemeStyle(
      id: "forest",
      title: "Orman Teması",
      emoji: "🌳",
      description: "Yeşil, sakin ve doğal görünüm.",
      gradient: [Color(0xFF66BB6A), Color(0xFF00897B)],
      background: Color(0xFFF1F8F4),
    ),
    ChildThemeStyle(
      id: "car",
      title: "Araba Teması",
      emoji: "🚗",
      description: "Enerjik mavi ve turuncu görünüm.",
      gradient: [Color(0xFF42A5F5), Color(0xFFFFA726)],
      background: Color(0xFFF2F7FF),
    ),
  ];

  static ChildThemeStyle findById(String? id) {
    return themes.firstWhere(
          (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}