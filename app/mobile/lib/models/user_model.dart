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
}
