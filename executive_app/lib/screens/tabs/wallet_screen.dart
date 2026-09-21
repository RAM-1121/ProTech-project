import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_data_provider.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  int _rewardPoints = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _isRedeeming = false;
  
  final TextEditingController _redeemController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _redeemController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<ApiDataProvider>(context, listen: false);
      final data = await provider.fetchWalletDetails();
      setState(() {
        _rewardPoints = data['rewardPoints'] ?? 0;
        _transactions = data['rewardTransactions'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallet: $e')),
        );
      }
    }
  }

  Future<void> _redeemPoints() async {
    final amount = int.tryParse(_redeemController.text) ?? 0;
    if (amount <= 0 || amount > _rewardPoints) return;

    setState(() => _isRedeeming = true);
    try {
      final provider = Provider.of<ApiDataProvider>(context, listen: false);
      final employeeId = provider.myProfile?['employeeId'];
      final employeeName = '${provider.myProfile?['firstName'] ?? ''} ${provider.myProfile?['lastName'] ?? ''}'.trim();
      
      if (employeeId == null) {
        throw Exception('User profile not fully loaded.');
      }
      
      await provider.submitApproval({
        'type': 'REWARD',
        'employeeId': employeeId,
        'employeeName': employeeName.isNotEmpty ? employeeName : 'Executive',
        'details': {
          'amount': amount,
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redeem request sent to Admin for approval!')),
        );
        _redeemController.clear();
        await _fetchWalletData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request redeem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Rewards')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available Points', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(
                                  '$_rewardPoints',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Redeem Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _redeemController,
                              builder: (context, value, _) {
                                final amount = int.tryParse(value.text) ?? 0;
                                final isInvalid = amount > _rewardPoints;
                                final isValid = amount > 0 && amount <= _rewardPoints;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _redeemController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: isInvalid ? Colors.red : null,
                                        fontWeight: isInvalid ? FontWeight.bold : null,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Enter points to redeem',
                                        prefixIcon: const Icon(Icons.card_giftcard),
                                        errorText: isInvalid ? 'Exceeds available balance' : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: (isValid && !_isRedeeming) ? _redeemPoints : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _isRedeeming
                                          ? const SizedBox(
                                              height: 20, width: 20, 
                                              child: CircularProgressIndicator(strokeWidth: 2)
                                            )
                                          : const Text('Redeem Now', style: TextStyle(fontSize: 16)),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    if (_transactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No transactions yet', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isEarn = tx['type'] == 'earn';
                          
                          DateTime? date;
                          try {
                            if (tx['date'] != null) {
                              date = DateTime.parse(tx['date']);
                            }
                          } catch (_) {}
                          
                          final dateStr = date != null ? DateFormat('MMM d, yyyy h:mm a').format(date) : 'Unknown Date';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isEarn ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                child: Icon(
                                  isEarn ? Icons.add_circle : Icons.remove_circle,
                                  color: isEarn ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(tx['title'] ?? 'Transaction'),
                              subtitle: Text(dateStr),
                              trailing: Text(
                                '${isEarn ? '+' : '-'}${tx['amount']}',
                                style: TextStyle(
                                  color: isEarn ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
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
