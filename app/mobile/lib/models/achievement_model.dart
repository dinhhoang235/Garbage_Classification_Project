class Achievement {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final double progress;
  final int targetCount;
  final int currentCount;
  final String iconName;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progress,
    required this.targetCount,
    required this.currentCount,
    this.iconName = 'award',
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isUnlocked: json['is_unlocked'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
      targetCount: json['target_count'] ?? 0,
      currentCount: json['current_count'] ?? 0,
      iconName: json['icon_name'] ?? 'award',
    );
  }
}
