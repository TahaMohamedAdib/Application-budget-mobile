import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/holding.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final totalValue = provider.getTotalPortfolioValue();
        final totalCost = provider.getTotalPortfolioCost();
        final gainLoss = provider.getTotalPortfolioGainLoss();
        final gainLossPercent = totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

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
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Portfolio',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 20, color: Colors.white),
                            onPressed: () => _showAddHoldingModal(context, provider),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Portfolio Summary Card
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.gold600,
                            AppTheme.gold700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.pie_chart,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Value',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\$${totalValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Cost',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Gain/Loss',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${gainLoss >= 0 ? '+' : ''}\$${gainLoss.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${gainLossPercent >= 0 ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Holdings List
                  Expanded(
                    child: provider.holdings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  size: 64,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No holdings yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add your first holding',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.holdings.length,
                            itemBuilder: (context, index) {
                              final holding = provider.holdings[index];
                              final isGain = holding.gainLoss >= 0;

                              return Dismissible(
                                key: Key(holding.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Holding?'),
                                      content: Text(
                                        'Are you sure you want to delete ${holding.symbol}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) {
                                  provider.deleteHolding(holding.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${holding.symbol} deleted'),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => _showEditHoldingModal(context, provider, holding),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.goldPrimary.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.show_chart,
                                                  color: AppTheme.goldPrimary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      holding.symbol.toUpperCase(),
                                                      style: Theme.of(context).textTheme.titleLarge,
                                                    ),
                                                    Text(
                                                      '${holding.shares} shares',
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '\$${holding.currentValue.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isGain
                                                          ? Colors.green.withOpacity(0.2)
                                                          : Colors.red.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '${isGain ? '+' : ''}${holding.gainLossPercent.toStringAsFixed(2)}%',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isGain ? Colors.green : Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            height: 1,
                                            color: Theme.of(context).dividerColor,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Avg Cost',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '\$${holding.costBasis.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Current Price',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '\$${holding.currentPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Gain/Loss',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '${isGain ? '+' : ''}\$${holding.gainLoss.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: isGain ? Colors.green : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (holding.notes != null && holding.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              holding.notes!,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddHoldingModal(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHoldingModal(
        onSave: (holding) {
          provider.addHolding(holding);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${holding.symbol} added')),
          );
        },
      ),
    );
  }

  void _showEditHoldingModal(BuildContext context, AppProvider provider, Holding holding) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHoldingModal(
        holding: holding,
        onSave: (updatedHolding) {
          provider.updateHolding(updatedHolding);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${updatedHolding.symbol} updated')),
          );
        },
      ),
    );
  }
}

class AddHoldingModal extends StatefulWidget {
  final Holding? holding;
  final Function(Holding) onSave;

  const AddHoldingModal({
    super.key,
    this.holding,
    required this.onSave,
  });

  @override
  State<AddHoldingModal> createState() => _AddHoldingModalState();
}

class _AddHoldingModalState extends State<AddHoldingModal> {
  final _symbolController = TextEditingController();
  final _sharesController = TextEditingController();
  final _costBasisController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.holding != null) {
      _symbolController.text = widget.holding!.symbol;
      _sharesController.text = widget.holding!.shares.toString();
      _costBasisController.text = widget.holding!.costBasis.toString();
      _currentPriceController.text = widget.holding!.currentPrice.toString();
      _notesController.text = widget.holding!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _sharesController.dispose();
    _costBasisController.dispose();
    _currentPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.holding == null ? 'Add Holding' : 'Edit Holding',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Symbol
              TextField(
                controller: _symbolController,
                decoration: InputDecoration(
                  labelText: 'Symbol',
                  hintText: 'e.g., AAPL, TSLA, BTC',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.show_chart),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Shares
              TextField(
                controller: _sharesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Shares',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),

              // Cost Basis
              TextField(
                controller: _costBasisController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Average Cost per Share',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),

              // Current Price
              TextField(
                controller: _currentPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Price per Share',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes about this holding',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveHolding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.holding == null ? 'Add Holding' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveHolding() {
    if (_symbolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a symbol')),
      );
      return;
    }

    final shares = double.tryParse(_sharesController.text) ?? 0;
    final costBasis = double.tryParse(_costBasisController.text) ?? 0;
    final currentPrice = double.tryParse(_currentPriceController.text) ?? 0;

    if (shares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid number of shares')),
      );
      return;
    }

    final holding = Holding(
      id: widget.holding?.id ?? const Uuid().v4(),
      symbol: _symbolController.text.toUpperCase(),
      shares: shares,
      costBasis: costBasis,
      currentPrice: currentPrice,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(holding);
  }
}
