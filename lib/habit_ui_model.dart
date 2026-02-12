import 'package:flutter/material.dart';

class HabitUIModel {
  final String id;
  final String title;
  final Color color;
  final IconData icon;
  final String tagText;

  const HabitUIModel({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.tagText,
  });
}
