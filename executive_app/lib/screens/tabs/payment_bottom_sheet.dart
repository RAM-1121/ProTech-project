import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_data_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentBottomSheet extends StatefulWidget {
  final Map<String, dynamic> task;

  const PaymentBottomSheet({super.key, required this.task});

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  bool _isLoadingData = true;
  bool _isPaymentPending = false;
  List<dynamic> _plans = [];
  List<dynamic> _coupons = [];

  String? _selectedCategory;
  String? _selectedPlanId;
  String? _selectedCouponId;

  double _basePrice = 0.0;
  double _discountAmount = 0.0;
  double _gstAmount = 0.0;
  double _finalAmount = 0.0;

  final List<String> _categories = ['AC Plan', 'Refrigerator Plan', 'Electrician Plan'];

  @override
  void initState() {
    super.initState();
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    if (status == 'payment pending') {
      _isPaymentPending = true;
      final billStr = widget.task['finalBill']?.toString() ?? '0';
      final cleanBill = billStr.replaceAll(RegExp(r'[^0-9.]'), '');
      _finalAmount = double.tryParse(cleanBill) ?? 0.0;
      _isLoadingData = false;
    } else {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    final provider = context.read<ApiDataProvider>();
    final plans = await provider.fetchPlans();
    final coupons = await provider.fetchCoupons();

    if (mounted) {
      setState(() {
        _plans = plans;
        _coupons = coupons;
        _isLoadingData = false;
      });
    }
  }

  void _calculateTotal() {
    double total = _basePrice;
    
    // Apply discount
    if (_selectedCouponId != null) {
      final selectedCoupon = _coupons.firstWhere((c) => c['id'] == _selectedCouponId, orElse: () => null);
      if (selectedCoupon != null) {
        String discountStr = selectedCoupon['discount'].toString();
        // Check if it's a percentage
        if (discountStr.contains('%')) {
          double pct = double.tryParse(discountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          _discountAmount = total * (pct / 100);
        } else {
          _discountAmount = double.tryParse(discountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }
      }
    } else {
      _discountAmount = 0.0;
    }

    double discountedTotal = total - _discountAmount;
    if (discountedTotal < 0) discountedTotal = 0;

    // Apply GST (18%)
    _gstAmount = discountedTotal * 0.18;
    
    _finalAmount = discountedTotal + _gstAmount;
  }

  Future<void> _submit(String status) async {
    if (!_isPaymentPending && _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Plan to proceed')));
      return;
    }

    final success = await context.read<ApiDataProvider>().updateTaskStatus(
      bookingId: widget.task['id'] ?? widget.task['_id'],
      status: status,
      finalBill: _finalAmount.toStringAsFixed(2),
      planId: _selectedPlanId,
      couponId: _selectedCouponId,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Status Updated Successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update task status')));
      }
    }
  }

  void _handleCash() {
    if (!_isPaymentPending && _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Plan first')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Collect Cash'),
          content: Text('Please collect cash: ₹${_finalAmount.toStringAsFixed(2)}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                // User pressed cancel, which means payment is pending but order is completed.
                _submit('Payment Pending');
              },
              child: const Text('Cancel (Pending Payment)', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                _submit('Completed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Collected'),
            ),
          ],
        );
      }
    );
  }

  void _handleQRCode() async {
    if (!_isPaymentPending && _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Plan first')));
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final upiId = await context.read<ApiDataProvider>().fetchCompanyUpiId();
    if (!mounted) return;
    
    Navigator.pop(context); // Hide loading

    if (upiId == null || upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID not configured by Admin')));
      return;
    }

    final upiUri = 'upi://pay?pa=$upiId&pn=Protech&am=${_finalAmount.toStringAsFixed(2)}&cu=INR';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scan to Pay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Amount: ₹${_finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: upiUri,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 8),
              Text('UPI: $upiId', style: const TextStyle(fontSize: 12, color: Color(0xFF800020))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close QR dialog
                _submit('Payment Pending');
              },
              child: const Text('Payment Failed/Pending', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close QR dialog
                _submit('Completed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Payment Received'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter plans by category
    final availablePlans = _selectedCategory == null 
        ? [] 
        : _plans.where((p) => p['category'].toString().toLowerCase() == _selectedCategory!.toLowerCase()).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: _isLoadingData 
          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('Complete Task & Billing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 24),
                  
                  if (!_isPaymentPending) ...[
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Plan Category (Required)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _selectedPlanId = null;
                          _basePrice = 0.0;
                          _calculateTotal();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Plan Dropdown
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedCategory),
                      decoration: const InputDecoration(
                        labelText: 'Select Plan (Required)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedPlanId,
                      items: availablePlans.isEmpty 
                        ? [const DropdownMenuItem<String>(value: null, child: Text('No plans available'))]
                        : availablePlans.map((p) => DropdownMenuItem<String>(
                            value: p['id'],
                            child: Text('${p['name']} (₹${p['price']})'),
                          )).toList(),
                      onChanged: availablePlans.isEmpty ? null : (val) {
                        setState(() {
                          _selectedPlanId = val;
                          if (val != null) {
                            final selectedPlan = _plans.firstWhere((p) => p['id'] == val);
                            _basePrice = double.tryParse(selectedPlan['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                          }
                          _calculateTotal();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Coupon Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Apply Coupon (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCouponId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Coupon'),
                        ),
                        ..._coupons.map((c) => DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text('${c['code']} (-₹${c['discount'].toString().replaceAll(RegExp(r'[^0-9.%]'), '')})'),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCouponId = val;
                          _calculateTotal();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Billing Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (!_isPaymentPending) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Base Amount:'),
                              Text('₹${_basePrice.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (_discountAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:', style: TextStyle(color: Colors.green)),
                                Text('-₹${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GST (18%):'),
                              Text('+₹${_gstAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          const Divider(height: 16, thickness: 1),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Final Payable:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹${_finalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCash,
                          icon: const Icon(Icons.money),
                          label: const Text('Cash'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleQRCode,
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Generate QR Code'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
