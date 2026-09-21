import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  String? _selectedCategory;
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _rewardPointsController = TextEditingController();
  String? _editingPlanId;

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _couponCodeController = TextEditingController();
  String? _editingCouponId;

  List<PlanItem> _plans = [];
  List<CouponItem> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final plansRes = await _apiService.get('/plans');
      final couponsRes = await _apiService.get('/plans/coupons');

      setState(() {
        _plans = (plansRes as List).map((p) => PlanItem(p['id'], p['category'], p['name'], p['price'], p['rewardPoints'])).toList();
        _coupons = (couponsRes as List).map((c) => CouponItem(c['id'], c['code'], c['discount'])).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlan() async {
    if (_selectedCategory == null || _serviceTypeController.text.isEmpty || _priceController.text.isEmpty) return;

    final data = {
      'category': _selectedCategory,
      'name': _serviceTypeController.text,
      'price': _priceController.text,
      'rewardPoints': _rewardPointsController.text,
    };

    try {
      if (_editingPlanId != null) {
        await _apiService.patch('/plans/$_editingPlanId', data);
      } else {
        await _apiService.post('/plans', data);
      }
      _clearPlanForm();
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving plan: $e')));
    }
  }

  Future<void> _deletePlan(String id) async {
    try {
      await _apiService.delete('/plans/$id');
      if (_editingPlanId == id) _clearPlanForm();
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting plan: $e')));
    }
  }

  void _clearPlanForm() {
    setState(() {
      _editingPlanId = null;
      _selectedCategory = null;
      _serviceTypeController.clear();
      _priceController.clear();
      _rewardPointsController.clear();
    });
  }

  Future<void> _saveCoupon() async {
    if (_discountController.text.isEmpty) return;

    String code = _couponCodeController.text.trim();
    if (code.isEmpty) {
      final randStr = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      code = 'PROMO-$randStr';
    }
    String discount = _discountController.text.trim();
    if (!discount.endsWith('%')) {
      discount += '%';
    }

    final data = {
      'code': code,
      'discount': discount,
    };

    try {
      if (_editingCouponId != null) {
        await _apiService.patch('/plans/coupons/$_editingCouponId', data);
      } else {
        await _apiService.post('/plans/coupons', data);
      }
      _clearCouponForm();
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving coupon: $e')));
    }
  }

  Future<void> _deleteCoupon(String id) async {
    try {
      await _apiService.delete('/plans/coupons/$id');
      if (_editingCouponId == id) _clearCouponForm();
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting coupon: $e')));
    }
  }

  void _clearCouponForm() {
    setState(() {
      _editingCouponId = null;
      _couponCodeController.clear();
      _discountController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading && _plans.isEmpty && _coupons.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.only(top: 24, left: 32, right: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Plans & Rewards',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 60, height: 60),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 4))
                      ]
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(height: 48, child: Center(child: Text('Tariff Packages', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis))),
                      Tab(height: 48, child: Center(child: Text('Discount Coupons', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTariffManager(),
                _buildCouponManager(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffManager() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Form
          Expanded(
            flex: 1,
            child: _buildFormCard(
              title: _editingPlanId != null ? 'Edit Tariff' : 'New Tariff',
              icon: Icons.add_chart_rounded,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCategory),
                  initialValue: _selectedCategory,
                  decoration: _inputDecoration('Category'),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  items: const [
                    DropdownMenuItem(value: 'AC Plan', child: Text('AC Plan', style: TextStyle(fontWeight: FontWeight.w600))),
                    DropdownMenuItem(value: 'Refrigerator Plan', child: Text('Refrigerator Plan', style: TextStyle(fontWeight: FontWeight.w600))),
                    DropdownMenuItem(value: 'Electrician Plan', child: Text('Electrician Plan', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 16),
                _buildTextField('Service Name (e.g., Installation)', controller: _serviceTypeController),
                const SizedBox(height: 16),
                _buildTextField('Price (₹)', controller: _priceController),
                const SizedBox(height: 16),
                _buildTextField('Reward Points', controller: _rewardPointsController),
                const SizedBox(height: 28),
                _buildCapsuleButton(
                  label: _editingPlanId != null ? 'Update Tariff' : 'Save Tariff',
                  onPressed: _savePlan,
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
                if (_editingPlanId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Center(
                      child: TextButton(
                        onPressed: _clearPlanForm,
                        child: const Text('Cancel Edit', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // List
          Expanded(
            flex: 2,
            child: _buildListCard(
              title: 'Active Tariffs',
              child: _buildTariffList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTariffList() {
    Map<String, List<PlanItem>> grouped = {};
    for (int i = 0; i < _plans.length; i++) {
      final p = _plans[i];
      if (!grouped.containsKey(p.category)) {
        grouped[p.category] = [];
      }
      grouped[p.category]!.add(p);
    }

    List<Widget> children = [];
    grouped.forEach((category, items) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0, left: 4),
        child: Text(
          category,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
      ));
      
      for (int j = 0; j < items.length; j++) {
        final plan = items[j];
        children.add(_buildTariffRow(plan));
        children.add(const SizedBox(height: 12));
      }
      children.add(const SizedBox(height: 20));
    });

    return ListView(children: children);
  }

  Widget _buildTariffRow(PlanItem plan) {
    return HoverableCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.handyman_rounded, color: Color(0xFF3B82F6)),
        ),
        title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('${plan.rewardPoints} Pts', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Text('₹${plan.price}', style: const TextStyle(fontSize: 14, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            _buildActionIcon(Icons.edit_rounded, const Color(0xFF3B82F6), () {
              setState(() {
                _editingPlanId = plan.id;
                _selectedCategory = plan.category;
                _serviceTypeController.text = plan.name;
                _priceController.text = plan.price;
                _rewardPointsController.text = plan.rewardPoints;
              });
            }),
            const SizedBox(width: 8),
            _buildActionIcon(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _deletePlan(plan.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponManager() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Form
          Expanded(
            flex: 1,
            child: _buildFormCard(
              title: _editingCouponId != null ? 'Edit Coupon' : 'Generate Coupon',
              icon: Icons.local_activity_rounded,
              children: [
                _buildTextField('Coupon Code (optional)', controller: _couponCodeController),
                const SizedBox(height: 16),
                _buildTextField('Discount %', controller: _discountController),
                const SizedBox(height: 28),
                _buildCapsuleButton(
                  label: _editingCouponId != null ? 'Update Coupon' : 'Generate Code',
                  onPressed: _saveCoupon,
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                  shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                ),
                if (_editingCouponId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Center(
                      child: TextButton(
                        onPressed: _clearCouponForm,
                        child: const Text('Cancel Edit', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // List
          Expanded(
            flex: 2,
            child: _buildListCard(
              title: 'Active Coupons',
              child: ListView.separated(
                itemCount: _coupons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildCouponRow(_coupons[index]),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCouponRow(CouponItem item) {
    return HoverableCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF9333EA).withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFF7E22CE)),
        ),
        title: Text(item.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E293B), letterSpacing: 1.2)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Text(item.discount, style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 16),
            _buildActionIcon(Icons.edit_rounded, const Color(0xFF3B82F6), () {
              setState(() {
                _editingCouponId = item.id;
                _couponCodeController.text = item.code;
                _discountController.text = item.discount.replaceAll('%', '');
              });
            }),
            const SizedBox(width: 8),
            _buildActionIcon(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _deleteCoupon(item.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 8))
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 8))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withValues(alpha: 0.1),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    );
  }

  Widget _buildTextField(String label, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label),
      style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildCapsuleButton({required String label, required VoidCallback onPressed, required Gradient gradient, required Color shadowColor}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}

class HoverableCard extends StatefulWidget {
  final Widget child;
  const HoverableCard({super.key, required this.child});
  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: _isHovered 
            ? [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: widget.child,
      ),
    );
  }
}

class PlanItem {
  String id;
  String category;
  String name;
  String price;
  String rewardPoints;

  PlanItem(this.id, this.category, this.name, this.price, this.rewardPoints);
}

class CouponItem {
  String id;
  String code;
  String discount;

  CouponItem(this.id, this.code, this.discount);
}
