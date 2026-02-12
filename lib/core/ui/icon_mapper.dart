import 'package:flutter/material.dart';

IconData iconFromName(String name) {
  switch (name) {
    case 'water':
      return Icons.water_drop;
    case 'pill':
    case 'vitamins':
      return Icons.medication;
    case 'sun':
      return Icons.wb_sunny;
    case 'moon':
      return Icons.nightlight_round;
    case 'skin':
      return Icons.spa;
    case 'check':
      return Icons.check_circle;
    default:
      return Icons.circle_outlined;
  }
}
