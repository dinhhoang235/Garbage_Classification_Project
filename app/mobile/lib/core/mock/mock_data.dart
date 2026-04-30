import '../../models/user_model.dart';

class MockData {
  static final User currentUser = User(
    id: '1',
    name: 'Minh Anh',
    phoneNumber: '0987654321',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1974&auto=format&fit=crop',
    points: 2450,
    level: 7,
    levelName: 'Eco Warrior',
    xpProgress: 0.82,
    achievementsCount: 12,
  );
}
