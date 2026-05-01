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

  String get initials {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'User',
      phoneNumber: json['phone_number'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      levelName: json['level_name'] ?? 'Người mới',
      xpProgress: (json['xp_progress'] ?? 0.0).toDouble(),
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
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? avatarUrl,
    int? points,
    int? level,
    String? levelName,
    double? xpProgress,
    int? achievementsCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      level: level ?? this.level,
      levelName: levelName ?? this.levelName,
      xpProgress: xpProgress ?? this.xpProgress,
      achievementsCount: achievementsCount ?? this.achievementsCount,
    );
  }
}
