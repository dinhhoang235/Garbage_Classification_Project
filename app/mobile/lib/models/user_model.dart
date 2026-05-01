class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String avatarUrl;
  final int points;
  final int level;
  final String levelName;
  final double xpProgress;
  final int achievementsCount;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.points,
    required this.level,
    required this.levelName,
    required this.xpProgress,
    required this.achievementsCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['full_name'] ?? json['username'] ?? 'User',
      phoneNumber: json['phone_number'] ?? '',
      avatarUrl: json['avatar_url'] ?? 'https://via.placeholder.com/150',
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      levelName: json['level_name'] ?? 'Beginner',
      xpProgress: (json['xp_progress'] ?? 0).toDouble(),
      achievementsCount: json['achievements_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'points': points,
      'level': level,
      'level_name': levelName,
      'xp_progress': xpProgress,
      'achievements_count': achievementsCount,
    };
  }
}
