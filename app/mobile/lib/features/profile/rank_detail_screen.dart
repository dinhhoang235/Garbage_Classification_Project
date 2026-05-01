import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';

class RankDetailScreen extends StatelessWidget {
  final User? user;

  const RankDetailScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranks = [
      {'lv': 1, 'name': 'Eco Seed', 'vn': 'Mầm non Xanh', 'xp': 0, 'desc': 'Bắt đầu hành trình sống xanh với những bước đi đầu tiên.', 'requirement': 'Đăng ký tài khoản thành công.'},
      {'lv': 2, 'name': 'Eco Sprout', 'vn': 'Chồi non Xanh', 'xp': 200, 'desc': 'Hạt giống đã nảy mầm, bạn đang dần hình thành thói quen tốt.', 'requirement': 'Quét và phân loại thành công 10 vật dụng.'},
      {'lv': 3, 'name': 'Eco Explorer', 'vn': 'Người khám phá', 'xp': 500, 'desc': 'Tìm hiểu sâu hơn về các phương pháp tái chế và bảo vệ môi trường.', 'requirement': 'Khám phá tất cả các danh mục rác và đạt 500 XP.'},
      {'lv': 4, 'name': 'Eco Guard', 'vn': 'Người bảo vệ', 'xp': 1000, 'desc': 'Luôn có ý thức bảo vệ môi trường trong mọi hoạt động hàng ngày.', 'requirement': 'Duy trì chuỗi 7 ngày phân loại rác liên tục.'},
      {'lv': 5, 'name': 'Eco Hero', 'vn': 'Anh hùng Xanh', 'xp': 1500, 'desc': 'Đóng góp tích cực và có sức ảnh hưởng đến những người xung quanh.', 'requirement': 'Đạt 5 thành tích và có 1.500 XP.'},
      {'lv': 6, 'name': 'Eco Master', 'vn': 'Bậc thầy Xanh', 'xp': 2000, 'desc': 'Sở hữu kiến thức uyên bác về phân loại rác và lối sống bền vững.', 'requirement': 'Phân loại đúng 100 vật dụng nhựa và kim loại.'},
      {'lv': 7, 'name': 'Eco Warrior', 'vn': 'Chiến binh Xanh', 'xp': 3000, 'desc': 'Sẵn sàng hành động vì một hành tinh xanh không rác thải.', 'requirement': 'Đạt 3.000 XP và hoàn thành 10 thành tích.'},
      {'lv': 8, 'name': 'Eco Guardian', 'vn': 'Hộ vệ Xanh', 'xp': 5000, 'desc': 'Người canh gác và bảo vệ sự đa dạng sinh học của trái đất.', 'requirement': 'Có 5.000 XP và chia sẻ 20 mẹo sống xanh.'},
      {'lv': 9, 'name': 'Eco Legend', 'vn': 'Huyền thoại Xanh', 'xp': 8000, 'desc': 'Một biểu tượng sống xanh truyền cảm hứng cho cả cộng đồng.', 'requirement': 'Đạt 8.000 XP và duy trì vị trí top 10 bảng xếp hạng tháng.'},
      {'lv': 10, 'name': 'Eco Sage', 'vn': 'Hiền triết Xanh', 'xp': 12000, 'desc': 'Đạt đến đỉnh cao của sự hòa hợp giữa con người và thiên nhiên.', 'requirement': 'Đạt 12.000 XP và hoàn thành tất cả các bộ sưu tập rác.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cấp bậc', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoCard(theme),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ranks.length,
              itemBuilder: (context, index) {
                final rank = ranks[index];
                final lv = rank['lv'] as int;
                final isCurrent = lv == user?.level;
                final isUnlocked = lv <= (user?.level ?? 0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primary.withAlpha(26) : theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : theme.dividerColor,
                      width: isCurrent ? 2 : 1,
                    ),
                    boxShadow: isCurrent ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(26),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isUnlocked ? AppColors.primary : theme.disabledColor.withAlpha(51),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'L$lv',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rank['name'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: isUnlocked ? theme.textTheme.titleMedium?.color : theme.disabledColor,
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Hiện tại',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  rank['vn'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isUnlocked ? AppColors.primary : theme.disabledColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor.withAlpha(100)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(LucideIcons.star, size: 16, color: AppColors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Yêu cầu: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? theme.textTheme.titleSmall?.color : theme.disabledColor,
                            ),
                          ),
                          Text(
                            '${rank['xp']} XP',
                            style: const TextStyle(fontSize: 13, color: AppColors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          rank['requirement'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnlocked ? theme.textTheme.bodyMedium?.color : theme.disabledColor.withAlpha(180),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rank['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isUnlocked ? theme.disabledColor : theme.disabledColor.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(theme.brightness == Brightness.dark ? 26 : 255),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.helpCircle, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Làm sao để thăng cấp?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(LucideIcons.scan, 'Quét rác hàng ngày (+10 XP/vật dụng)'),
          _buildRequirementItem(LucideIcons.award, 'Hoàn thành các thành tích đặc biệt'),
          _buildRequirementItem(LucideIcons.users, 'Chia sẻ mẹo sống xanh cho cộng đồng'),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withAlpha(180)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
