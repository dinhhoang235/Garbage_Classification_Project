import 'package:flutter/material.dart';

class WasteCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> examples;
  final String disposalGuide;

  WasteCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
    required this.disposalGuide,
  });
}
