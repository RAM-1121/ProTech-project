import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
class ProfilePage extends StatefulWidget {
  final XFile? currentImage;
  final ValueChanged<XFile?>? onSaveImage;

  const ProfilePage({super.key, this.currentImage, this.onSaveImage});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  XFile? _tempProfileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController =
      TextEditingController(text: '');
  final TextEditingController _idController =
      TextEditingController(text: '');
  final TextEditingController _mobileController =
      TextEditingController(text: '');

  final List<Map<String, TextEditingController>> _customFields = [];

  @override
  void initState() {
    super.initState();
    _tempProfileImage = widget.currentImage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user != null) {
        setState(() {
          if (user['mobile'] != null) {
            _mobileController.text = user['mobile'].toString();
          }
          if (user['name'] != null) {
            _nameController.text = user['name'].toString();
          }
          if (user['employeeId'] != null) {
            _idController.text = user['employeeId'].toString();
          } else if (user['id'] != null) {
            _idController.text = user['id'].toString();
          }
        });
      }
    });
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _tempProfileImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: !_isEditing,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _mobileController.dispose();
    for (var field in _customFields) {
      field['field']?.dispose();
      field['reason']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final profileTitle = auth.isMasterAdmin 
                  ? 'Master Admin Profile' 
                  : 'Assistant Admin Profile';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(profileTitle,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(
                      width: 60, height: 60), // Spacer for global bell icon
                ],
              );
            }
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Details Card
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20)
                        ]),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Admin Profile',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  const Text('Edit Mode',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _isEditing,
                                    onChanged: (val) {
                                      setState(() {
                                        _isEditing = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.blueAccent.shade100,
                                    backgroundImage: _tempProfileImage != null
                                        ? (kIsWeb
                                            ? NetworkImage(_tempProfileImage!.path)
                                            : FileImage(
                                                    File(_tempProfileImage!.path))
                                                as ImageProvider)
                                        : null,
                                    child: _tempProfileImage == null
                                        ? const Icon(Icons.person,
                                            size: 60, color: Colors.white)
                                        : null,
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField('Full Name', _nameController),
                          const SizedBox(height: 16),
                          _buildTextField('Employee ID', _idController),
                          const SizedBox(height: 16),
                          _buildTextField('Mobile Number', _mobileController),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Additional Information',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              if (_isEditing)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _customFields.add({
                                        'field': TextEditingController(),
                                        'reason': TextEditingController()
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Field & Reason'),
                                )
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._customFields.map((field) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _buildTextField(
                                          'Field Name', field['field']!)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildTextField(
                                          'Reason / Value', field['reason']!)),
                                  if (_isEditing)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
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
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final authProvider = context.read<AuthProvider>();
                                await authProvider.logout();
                                if (!context.mounted) return;
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text('Secure Logout',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Bank / UPI Configuration (Kept from previous)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20)
                        ]),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Payment Configuration',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'These details are used to generate the dynamic QR codes in the Executive App.',
                            style: TextStyle(color: Colors.blueGrey.shade400),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            readOnly: !_isEditing,
                            decoration: InputDecoration(
                              labelText: 'Bank Name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: _isEditing
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            readOnly: !_isEditing,
                            decoration: InputDecoration(
                              labelText: 'Account Number',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: _isEditing
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            readOnly: !_isEditing,
                            decoration: InputDecoration(
                              labelText: 'IFSC Code',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: _isEditing
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR')),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            readOnly: !_isEditing,
                            decoration: InputDecoration(
                              labelText: 'UPI ID (e.g., business@okbank)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: _isEditing
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_isEditing)
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  if (widget.onSaveImage != null) {
                                    widget.onSaveImage!(_tempProfileImage);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Save All Profile Details',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
