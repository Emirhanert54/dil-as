import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionFlowService {
  SessionFlowService._();

  static final ValueNotifier<bool> forceAdultLogin = ValueNotifier(false);

  static const String _activeChildIdKey = "active_child_id";

  static void goToAdultLogin() {
    forceAdultLogin.value = true;
  }

  static void allowChildAutoStart() {
    forceAdultLogin.value = false;
  }

  static Future<void> saveActiveChildId(String childId) async {
    final clean = childId.trim();
    if (clean.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeChildIdKey, clean);
  }

  static Future<String?> getActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activeChildIdKey)?.trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> clearActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeChildIdKey);
  }
}