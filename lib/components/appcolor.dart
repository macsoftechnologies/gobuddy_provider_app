import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFC8BB47);      // Green shade 1
  static const Color secondary = Color(0xFF25AC2C);


  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
