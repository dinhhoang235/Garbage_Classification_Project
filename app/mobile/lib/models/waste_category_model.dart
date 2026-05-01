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

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: Icons.category, // Fallback icon
      color: Colors.green, // Fallback color
      examples: List<String>.from(json['examples'] ?? []),
      disposalGuide: json['disposal_guide'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'examples': examples,
      'disposal_guide': disposalGuide,
    };
  }
}
