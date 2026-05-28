import 'package:flutter/material.dart';

class AppColors {
  // Warna Utama
  static const Color primaryAqua = Color(0xFF52B6DF);
  static const Color primaryDark = Color(0xFF3F4E5A);

  // Warna Latar & Card
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F9FD);

  // Warna Teks
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSubtitle = Color(0xFF64748B);

  // Gradien untuk tombol
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2E93B9), Color(0xFF52B6DF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
