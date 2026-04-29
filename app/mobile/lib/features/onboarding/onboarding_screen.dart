import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/eco_button.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text(
                    'ECO SORT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Phân loại rác thải\nvì một tương lai xanh 🌱',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Image.network(
                'https://cdn-icons-png.flaticon.com/512/3067/3067451.png',
                height: 250,
              ),
              const Spacer(),
              const Text(
                'Phân loại rác\nBảo vệ môi trường',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cùng nhau xây dựng một thế giới\nsạch hơn và xanh hơn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Container(width: 24, height: 8, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle)),
                ],
              ),
              const Spacer(),
              EcoButton(
                label: 'Bắt đầu',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
