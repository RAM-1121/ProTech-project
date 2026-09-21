import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';


const MaterialColor burgundy = MaterialColor(
  0xFF800020,
  <int, Color>{
    50: Color(0xFFF0E5E8),
    100: Color(0xFFDBBFC6),
    200: Color(0xFFC495A0),
    300: Color(0xFFAC6B7A),
    400: Color(0xFF994B5D),
    500: Color(0xFF800020),
    600: Color(0xFF78001C),
    700: Color(0xFF6D0017),
    800: Color(0xFF630012),
    900: Color(0xFF50000A),
  },
);

class Employee {
  String id;
  String name;
  String phone;
  String status;
  MaterialColor color;
  String bloodGroup;
  DateTime? doj;
  String experience;
  String bankDetails;
  List<Map<String, String>> customFields;
  DateTime? leaveStartDate;
  DateTime? leaveEndDate;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.color,
    this.bloodGroup = '',
    this.doj,
    this.experience = '',
    this.bankDetails = '',
    this.customFields = const [],
    this.leaveStartDate,
    this.leaveEndDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    String rawStatus = json['status'] ?? 'Active';
    String computedStatus = rawStatus;

    final leaveStart = json['leaveStartDate'] != null ? DateTime.parse(json['leaveStartDate']) : null;
    final leaveEnd = json['leaveEndDate'] != null ? DateTime.parse(json['leaveEndDate']) : null;

    if (rawStatus == 'Offline' && leaveStart != null && leaveEnd != null) {
      final now = DateTime.now();
      final start = DateTime(leaveStart.year, leaveStart.month, leaveStart.day);
      final end = DateTime(leaveEnd.year, leaveEnd.month, leaveEnd.day, 23, 59, 59);
      if (now.isAfter(start) && now.isBefore(end) || now.isAtSameMomentAs(start)) {
        computedStatus = 'On Leave';
      }
    }

    return Employee(
      id: json['employeeId'] ?? json['id'] ?? '',
      name: json['firstName'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      status: computedStatus,
      color: burgundy,
      bloodGroup: json['bloodGroup'] ?? '',
      doj: json['doj'] != null ? DateTime.parse(json['doj']) : null,
      experience: json['experience'] ?? '',
      bankDetails: json['bankDetails'] ?? '',
      leaveStartDate: json['leaveStartDate'] != null ? DateTime.parse(json['leaveStartDate']) : null,
      leaveEndDate: json['leaveEndDate'] != null ? DateTime.parse(json['leaveEndDate']) : null,
      customFields: (json['customFields'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
    );
  }
}

class EmployeePage extends StatefulWidget {
  final int initialIndex;
  const EmployeePage({super.key, this.initialIndex = 0});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  List<Employee> _employees = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  late WebSocketService _webSocketService;
  
  void _onUpdateReceived(dynamic data) {
    if (data != null && data['type'] == 'EXECUTIVE_UPDATE') {
      _fetchEmployees();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webSocketService = Provider.of<WebSocketService>(context, listen: false);
      _webSocketService.addListener(_onUpdateReceived);
    });
  }

  @override
  void dispose() {
    if (mounted) {
      _webSocketService.removeListener(_onUpdateReceived);
    }
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await _apiService.get('/users/executives');
      final List<dynamic> data = response ?? []; // ApiService returns decoded JSON
      setState(() {
        _employees = data.where((e) => e != null).map((json) => Employee.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees: $e')),
        );
      }
    }
  }

  String _getColorHex(MaterialColor color) {
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.red) return 'red';
    return 'green';
  }
  Future<void> _addEmployee(Employee emp) async {
    try {
      await _apiService.post('/users/executives', {
        'employeeId': emp.id,
        'firstName': emp.name,
        'phone': emp.phone,
        'status': emp.status,
        'color': _getColorHex(emp.color),
        'bloodGroup': emp.bloodGroup,
        'doj': emp.doj?.toIso8601String(),
        'experience': emp.experience,
        'bankDetails': emp.bankDetails,
        'leaveStartDate': emp.leaveStartDate?.toIso8601String(),
        'leaveEndDate': emp.leaveEndDate?.toIso8601String(),
        'customFields': emp.customFields,
      });
      _fetchEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add employee: $e'), backgroundColor: Colors.redAccent),
        );
      }
      rethrow;
    }
  }

  Future<void> _updateEmployee(Employee emp) async {
    try {
      await _apiService.patch('/users/executives/${emp.id}', {
        'firstName': emp.name,
        'phone': emp.phone,
        'status': emp.status,
        'color': _getColorHex(emp.color),
        'bloodGroup': emp.bloodGroup,
        'doj': emp.doj?.toIso8601String(),
        'experience': emp.experience,
        'bankDetails': emp.bankDetails,
        'leaveStartDate': emp.leaveStartDate?.toIso8601String(),
        'leaveEndDate': emp.leaveEndDate?.toIso8601String(),
        'customFields': emp.customFields,
      });
      _fetchEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update employee: $e'), backgroundColor: Colors.redAccent),
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteEmployee(Employee emp) async {
    try {
      await _apiService.delete('/users/executives/${emp.id}');
      _fetchEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete employee: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMasterAdmin = auth.isMasterAdmin;

    return DefaultTabController(
      length: isMasterAdmin ? 3 : 2,
      initialIndex: widget.initialIndex < (isMasterAdmin ? 3 : 2) ? widget.initialIndex : 0,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 24, left: 32, right: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Employee Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 60, height: 60),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.blueGrey.shade600,
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 0))
                        ]),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      const Tab(
                          height: 44,
                          child: Center(
                              child: Text('List of Employees',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      const Tab(
                          height: 44,
                          child: Center(
                              child: Text('Active / Leave',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      if (isMasterAdmin)
                        const Tab(
                            height: 44,
                            child: Center(
                                child: Text('Register New Employee',
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildAllEmployeesList(context, isMasterAdmin),
                      _buildCategorizedList(context, isMasterAdmin),
                      if (isMasterAdmin) _buildRegistrationForm(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildAllEmployeesList(BuildContext context, bool isMasterAdmin) {
    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
            ]),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _employees.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            return _buildEmployeeRow(context, _employees[index],
                showStatus: false, isMasterAdmin: isMasterAdmin);
          },
        ),
      ),
    );
  }

  Widget _buildCategorizedList(BuildContext context, bool isMasterAdmin) {
    final active = _employees.where((e) => e.status == 'Active').toList();
    final leave = _employees.where((e) => e.status == 'On Leave').toList();
    final offline =
        _employees.where((e) => e.status == 'Offline').toList();

    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
            ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (active.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Active Employees',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: burgundy)),
              ),
              ...active.map((e) => _buildEmployeeRow(context, e, isMasterAdmin: isMasterAdmin)),
            ],
            if (leave.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 8),
                child: Text('Employees on Leave',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: burgundy)),
              ),
              ...leave.map((e) => _buildEmployeeRow(context, e, isMasterAdmin: isMasterAdmin)),
            ],
            if (offline.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 8),
                child: Text('Offline Employees',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: burgundy)),
              ),
              ...offline.map((e) => _buildEmployeeRow(context, e, isMasterAdmin: isMasterAdmin)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeRow(BuildContext context, Employee emp,
      {bool showStatus = true, bool isMasterAdmin = false}) {
    return ListTile(
      onTap: () => _showExecutiveProfile(context, emp),
      leading: CircleAvatar(
        backgroundColor: burgundy.withValues(alpha: 0.1),
        child: Icon(Icons.person, color: burgundy),
      ),
      title:
          Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('ID: ${emp.id} | Phone: ${emp.phone}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStatus)
            Chip(
              label: Text(emp.status),
              backgroundColor: burgundy.shade50,
              labelStyle: TextStyle(
                color: burgundy.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (showStatus) const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              tooltip: 'Edit Employee',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: SizedBox(
                      width: 600,
                      height: 800,
                      child: EmployeeRegistrationForm(
                        employeeToEdit: emp,
                        onSave: (updatedEmp) {
                          _updateEmployee(updatedEmp);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Employee updated successfully!')),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          if (isMasterAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Delete Employee',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Employee'),
                    content:
                        Text('Are you sure you want to delete ${emp.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteEmployee(emp);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Employee deleted successfully!')),
                          );
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showExecutiveProfile(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: burgundy.withValues(alpha: 0.1),
                    child: Icon(Icons.person, size: 60, color: burgundy),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emp.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Executive ID: ${emp.id}',
                    style: TextStyle(
                        fontSize: 16, color: Colors.blueGrey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    label: Text(emp.status),
                    backgroundColor: burgundy.shade50,
                    labelStyle: TextStyle(
                        color: burgundy.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildProfileDetailRow('Phone', emp.phone, Icons.phone),
                  _buildProfileDetailRow(
                      'Blood Group',
                      emp.bloodGroup.isEmpty ? 'N/A' : emp.bloodGroup,
                      Icons.bloodtype),
                  _buildProfileDetailRow(
                      'Experience',
                      emp.experience.isEmpty ? 'N/A' : emp.experience,
                      Icons.work_history),
                  _buildProfileDetailRow(
                      'DOJ',
                      emp.doj != null
                          ? '${emp.doj!.day}/${emp.doj!.month}/${emp.doj!.year}'
                          : 'N/A',
                      Icons.calendar_today),
                  _buildProfileDetailRow(
                      'Bank Details',
                      emp.bankDetails.isEmpty ? 'N/A' : emp.bankDetails,
                      Icons.account_balance),
                  if (emp.customFields.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Additional Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...emp.customFields.map((field) => _buildProfileDetailRow(
                        field['title'] ?? '',
                        field['value'] ?? '',
                        Icons.info_outline)),
                  ],
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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

  Widget _buildProfileDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13, color: Colors.blueGrey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return EmployeeRegistrationForm(
      existingEmployees: _employees,
      onSave: (newEmp) {
        _addEmployee(newEmp);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee registered successfully!')),
        );
      },
    );
  }
}

class EmployeeRegistrationForm extends StatefulWidget {
  final Employee? employeeToEdit;
  final Function(Employee) onSave;
  final List<Employee> existingEmployees;

  const EmployeeRegistrationForm({
    super.key,
    this.employeeToEdit,
    required this.onSave,
    this.existingEmployees = const [],
  });

  @override
  State<EmployeeRegistrationForm> createState() =>
      _EmployeeRegistrationFormState();
}

class _EmployeeRegistrationFormState extends State<EmployeeRegistrationForm> {
  DateTime? _dateOfJoining;
  DateTime? _leaveStartDate;
  DateTime? _leaveEndDate;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  String _selectedStatus = 'Active';
  String? _idError;

  final List<Map<String, TextEditingController>> _customFields = [];

  @override
  void initState() {
    super.initState();
    if (widget.employeeToEdit != null) {
      final emp = widget.employeeToEdit!;
      _idController.text = emp.id;
      _nameController.text = emp.name;
      _phoneController.text = emp.phone;
      _bloodGroupController.text = emp.bloodGroup;
      _experienceController.text = emp.experience;
      _bankController.text = emp.bankDetails;
      _dateOfJoining = emp.doj;
      _leaveStartDate = emp.leaveStartDate;
      _leaveEndDate = emp.leaveEndDate;
      _selectedStatus = emp.status;

      for (var field in emp.customFields) {
        _customFields.add({
          'title': TextEditingController(text: field['title']),
          'value': TextEditingController(text: field['value']),
        });
      }
    }
  }

  void _calculateExperience(DateTime doj) {
    final now = DateTime.now();
    int years = now.year - doj.year;
    int months = now.month - doj.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    String experienceText = '';
    if (years > 0) experienceText += '$years Years ';
    if (months > 0) experienceText += '$months Months';
    if (experienceText.isEmpty) {
      final days = now.difference(doj).inDays;
      experienceText = '$days Days';
    }
    _experienceController.text = experienceText.trim();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfJoining ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfJoining) {
      setState(() {
        _dateOfJoining = picked;
      });
      _calculateExperience(picked);
    }
  }

  Widget _buildTextField(String label,
      {String? helperText,
      String? errorText,
      TextEditingController? controller,
      bool readOnly = false,
      VoidCallback? onTap,
      ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  MaterialColor _getColorForStatus(String status) {
    return burgundy;
  }

  void _handleSave() {
    final enteredId = _idController.text.trim();
    if (enteredId.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee ID and Name are required')),
      );
      return;
    }

    if (widget.employeeToEdit == null) {
      // New employee registration check
      final isDuplicate = widget.existingEmployees.any(
          (emp) => emp.id.toLowerCase() == enteredId.toLowerCase());
      if (isDuplicate) {
        setState(() {
          _idError = 'ID "$enteredId" is already created.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee ID "$enteredId" is already created.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final List<Map<String, String>> customFieldsData = _customFields.map((f) {
      return {'title': f['title']!.text, 'value': f['value']!.text};
    }).toList();

    final newEmp = Employee(
      id: enteredId,
      name: _nameController.text,
      phone: _phoneController.text,
      status: _selectedStatus,
      color: _getColorForStatus(_selectedStatus),
      bloodGroup: _bloodGroupController.text,
      doj: _dateOfJoining,
      experience: _experienceController.text,
      bankDetails: _bankController.text,
      leaveStartDate: _selectedStatus == 'On Leave' ? _leaveStartDate : null,
      leaveEndDate: _selectedStatus == 'On Leave' ? _leaveEndDate : null,
      customFields: customFieldsData,
    );

    widget.onSave(newEmp);

    if (widget.employeeToEdit == null) {
      // Clear form after new registration
      setState(() {
        _idController.clear();
        _nameController.clear();
        _phoneController.clear();
        _bloodGroupController.clear();
        _experienceController.clear();
        _bankController.clear();
        _dateOfJoining = null;
        _leaveStartDate = null;
        _leaveEndDate = null;
        _selectedStatus = 'Active';
        _customFields.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.employeeToEdit != null;
    return Container(
      color: isEditing ? Colors.white : const Color(0xFFF4F7FC),
      padding: isEditing ? const EdgeInsets.all(16) : const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: isEditing
              ? null
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20)
                    ]),
          padding: isEditing ? EdgeInsets.zero : const EdgeInsets.all(32),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(isEditing ? 'Edit Employee' : 'Register Employee',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (!isEditing) ...[
                const SizedBox(height: 8),
                const Text(
                    'Note: Executive login requires the Employee ID. Unregistered IDs cannot log in.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              _buildTextField('Employee ID *',
                  controller: _idController,
                  helperText:
                      isEditing ? null : 'Mandatory for executive login',
                  errorText: _idError,
                  readOnly: isEditing,
                  onChanged: (val) {
                    if (isEditing) return;
                    final isDuplicate = widget.existingEmployees.any((emp) =>
                        emp.id.toLowerCase() == val.trim().toLowerCase());
                    setState(() {
                      if (isDuplicate) {
                        _idError = 'ID "$val" is already created.';
                      } else {
                        _idError = null;
                      }
                    });
                  }), // Don't allow ID edit if already created
              const SizedBox(height: 16),
              _buildTextField('Full Name *', controller: _nameController),
              const SizedBox(height: 16),
              _buildTextField('Mobile Number *', controller: _phoneController),
              const SizedBox(height: 16),
              _buildTextField('Blood Group', controller: _bloodGroupController),
              const SizedBox(height: 16),
              _buildTextField(
                'Date of Joining',
                controller: TextEditingController(
                    text: _dateOfJoining != null
                        ? "${_dateOfJoining!.day}/${_dateOfJoining!.month}/${_dateOfJoining!.year}"
                        : ""),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              _buildTextField('Experience', controller: _experienceController),
              const SizedBox(height: 16),
              _buildTextField('Bank Account / UPI Details',
                  controller: _bankController),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: ['Active', 'On Leave', 'Offline'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    if (newValue != null) _selectedStatus = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Additional Details',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _customFields.add({
                          'title': TextEditingController(),
                          'value': TextEditingController()
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Field'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              ..._customFields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildTextField('Detail Title',
                              controller: field['title'])),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField('Detail Value',
                              controller: field['value'])),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _customFields.remove(field);
                          });
                        },
                      )
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isEditing ? 'Save Changes' : 'Register Executive',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              if (isEditing) const SizedBox(height: 16)
            ],
          ),
        ),
      ),
    );
  }
}
