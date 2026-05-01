import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/user_model.dart';
import '../../models/waste_category_model.dart';
import '../theme/app_colors.dart';

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

  static final List<WasteCategory> categories = [
    WasteCategory(
      id: 'plastic',
      name: 'Nhựa',
      description: 'Các loại chai lọ, túi nilon và đồ nhựa dùng một lần.',
      icon: LucideIcons.glassWater,
      color: AppColors.blue,
      examples: ['Chai nước suối', 'Hộp cơm nhựa', 'Túi nilon', 'Ống hút'],
      disposalGuide: 'Rửa sạch, làm khô và cho vào thùng rác tái chế.',
    ),
    WasteCategory(
      id: 'paper',
      name: 'Giấy',
      description: 'Sách vở cũ, báo chí, thùng carton và giấy văn phòng.',
      icon: LucideIcons.fileText,
      color: AppColors.orange,
      examples: ['Thùng carton', 'Giấy A4', 'Tạp chí', 'Vỏ hộp sữa'],
      disposalGuide: 'Gấp gọn và giữ cho giấy luôn khô ráo.',
    ),
    WasteCategory(
      id: 'metal',
      name: 'Kim loại',
      description: 'Lon nước ngọt, vỏ đồ hộp và các vật dụng bằng kim loại khác.',
      icon: LucideIcons.hammer,
      color: Colors.blueGrey,
      examples: ['Lon bia', 'Vỏ đồ hộp', 'Thìa nĩa hỏng', 'Dây điện cũ'],
      disposalGuide: 'Làm sạch và loại bỏ các phần nhựa đính kèm nếu có.',
    ),
    WasteCategory(
      id: 'organic',
      name: 'Hữu cơ',
      description: 'Thức ăn thừa, vỏ trái cây, rau củ và lá cây.',
      icon: LucideIcons.leaf,
      color: AppColors.primary,
      examples: ['Vỏ cam', 'Cơm thừa', 'Lá cây khô', 'Bã cà phê'],
      disposalGuide: 'Bỏ vào thùng rác hữu cơ để làm phân bón.',
    ),
    WasteCategory(
      id: 'electronic',
      name: 'Pin & Điện tử',
      description: 'Các loại pin cũ, sạc điện thoại và linh kiện điện tử hỏng.',
      icon: LucideIcons.zap,
      color: AppColors.red,
      examples: ['Pin AA', 'Sạc điện thoại', 'Tai nghe hỏng', 'Bàn phím'],
      disposalGuide: 'Phân loại riêng vì chứa chất độc hại, cần xử lý đặc biệt.',
    ),
  ];
}
