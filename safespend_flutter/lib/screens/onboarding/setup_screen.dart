import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/account.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const SetupScreen({super.key, required this.onComplete, required this.onBack});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _incomeController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _balanceController = TextEditingController();
  int _currentStep = 0;

  @override
  void dispose() {
    _incomeController.dispose();
    _accountNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

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
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentStep == 0 ? widget.onBack : _previousStep,
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 2,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: _currentStep == 0 ? _buildIncomeStep() : _buildAccountStep(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _currentStep == 0 ? _nextStep : _complete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentStep == 0 ? 'Next' : 'Get Started',
                      style: const TextStyle(
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

  Widget _buildIncomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your monthly income?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us calculate your safe-to-spend amount',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _incomeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            labelText: 'Monthly Income',
            hintText: '0.00',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.goldPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.goldPrimary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.goldPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Don\'t worry, you can change this later in Settings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your first account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start with your main checking account',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _accountNameController,
          decoration: InputDecoration(
            labelText: 'Account Name',
            hintText: 'e.g., Checking Account',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _balanceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current Balance',
            hintText: '0.00',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data is stored securely on your device',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _nextStep() {
    if (_incomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your monthly income')),
      );
      return;
    }

    setState(() => _currentStep = 1);
  }

  void _previousStep() {
    setState(() => _currentStep = 0);
  }

  void _complete() {
    if (_accountNameController.text.isEmpty || _balanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Save income
    final income = double.tryParse(_incomeController.text) ?? 0;
    provider.updateSettings(
      provider.settings.copyWith(monthlyIncome: income),
    );

    // Add first account
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final account = Account(
      id: const Uuid().v4(),
      name: _accountNameController.text,
      type: 'bank',
      balance: balance,
      color: '#3B82F6', // Blue
      includeInNetWorth: true,
    );
    provider.addAccount(account);

    widget.onComplete();
  }
}
