import 'package:flutter/material.dart';
import 'package:safespend_flutter/theme/ios_icons.dart';
import '../../theme/app_theme.dart';

class PreviewScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PreviewScreen({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(IOSIcons.arrow_back),
                      onPressed: onBack,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Everything You Need',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'All your finances in one place',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      _buildPreviewCard(
                        context,
                        'Today',
                        'See your safe-to-spend amount and recent activity',
                        IOSIcons.today,
                      ),
                      _buildPreviewCard(
                        context,
                        'Plan',
                        'Manage bills and recurring expenses',
                        IOSIcons.calendar_month,
                      ),
                      _buildPreviewCard(
                        context,
                        'Wealth',
                        'Track your net worth and investments',
                        IOSIcons.trending_up,
                      ),
                      _buildPreviewCard(
                        context,
                        'Accounts',
                        'Manage all your bank accounts',
                        IOSIcons.account_balance_wallet,
                      ),
                      _buildPreviewCard(
                        context,
                        'AI Coach',
                        'Get personalized financial advice',
                        IOSIcons.psychology,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Let\'s Set Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.adaptiveIconSurface(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  Icon(icon, color: AppTheme.adaptiveIcon(context), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
