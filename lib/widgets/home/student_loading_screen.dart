import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';
class StudentLoadingScreen extends StatelessWidget {
  const StudentLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: u.currentTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 18),
            Text(
              "Bilgilerin hazırlanıyor...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}