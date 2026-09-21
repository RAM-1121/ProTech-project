import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class SoundItem {
  final String name;
  bool isActive;

  SoundItem(this.name, {this.isActive = false});
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isEditingUpi = false;
  bool _isLoadingUpi = true;
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _upiNameController =
      TextEditingController(text: 'ProTech Services');
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUpiId();
  }

  Future<void> _fetchUpiId() async {
    try {
      final response = await _apiService.get('/payments/upi-id');
      if (mounted) {
        setState(() {
          _upiIdController.text = response['upiId'] ?? '';
          _isLoadingUpi = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching UPI ID: $e');
      if (mounted) {
        setState(() {
          _isLoadingUpi = false;
        });
      }
    }
  }

  Future<void> _saveUpiId() async {
    if (_upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID.')),
      );
      return;
    }

    try {
      await _apiService.post('/payments/upi-id', {
        'upiId': _upiIdController.text,
      });
      if (mounted) {
        setState(() {
          _isEditingUpi = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company UPI Details saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save UPI ID: $e')),
        );
      }
    }
  }

  final List<SoundItem> _uploadedSounds = [
    SoundItem('Admin web alert.wav', isActive: true),
  ];
  Future<void> _pickSoundFile() async {
    try {
      PlatformFile? file = await FilePicker.pickFile(
        type: FileType.audio,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final extension = file.name.split('.').last.toLowerCase();
        
        // Map common audio extensions to mime types
        String mimeType = 'audio/wav';
        if (extension == 'mp3') {
          mimeType = 'audio/mpeg';
        } else if (extension == 'ogg') {
          mimeType = 'audio/ogg';
        } else if (extension == 'aac') {
          mimeType = 'audio/aac';
        }
        
        final dataUri = 'data:$mimeType;base64,$base64String';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_alert_sound', dataUri);

        setState(() {
          for (var s in _uploadedSounds) {
            s.isActive = false;
          }
          _uploadedSounds.add(SoundItem(file.name, isActive: true));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Alert sound "${file.name}" uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking sound file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Portal Configuration and Admin Preferences',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              // Notification Settings Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.blue.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_rounded,
                              color: Colors.blueAccent, size: 32),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alert Sound',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload a custom audio file (.mp3, .wav) for new notification alerts.',
                                style:
                                    TextStyle(color: Colors.blueGrey.shade600),
                              ),
                            ],
                          ),
                        ),
                          ElevatedButton.icon(
                            onPressed: _pickSoundFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Sound'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                      ],
                    ),
                    if (_uploadedSounds.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text('Uploaded Sounds',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_uploadedSounds.length, (index) {
                        final sound = _uploadedSounds[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sound.isActive
                                    ? Colors.blueAccent
                                    : Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.audiotrack,
                                color: sound.isActive
                                    ? Colors.blueAccent
                                    : Colors.grey),
                            title: Text(sound.name,
                                style: TextStyle(
                                    fontWeight: sound.isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            trailing: Switch(
                              value: sound.isActive,
                              activeThumbColor: Colors.blueAccent,
                              onChanged: (bool value) {
                                setState(() {
                                  if (value) {
                                    // Turn off all others
                                    for (var s in _uploadedSounds) {
                                      s.isActive = false;
                                    }
                                    _uploadedSounds[index].isActive = true;
                                  } else {
                                    // Allow turning off the current sound
                                    _uploadedSounds[index].isActive = false;
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Company UPI Details Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.green.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.qr_code_2_rounded,
                              color: Colors.green.shade600, size: 32),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Company UPI Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set the primary UPI ID. Field executives will automatically generate dynamic QR codes based on this ID to collect payments.',
                                style:
                                    TextStyle(color: Colors.blueGrey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingUpi)
                      const Center(child: CircularProgressIndicator())
                    else if (!_isEditingUpi)
                      // Active View
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payee Name',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey.shade400,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _upiNameController.text.isNotEmpty
                                        ? _upiNameController.text
                                        : 'Not Specified',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UPI ID (VPA)',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey.shade400,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _upiIdController.text,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.green.shade300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle_rounded,
                                                color: Colors.green.shade600,
                                                size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Edit View
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _upiNameController,
                              decoration: InputDecoration(
                                labelText: 'Payee Name (Optional)',
                                hintText: 'e.g., ProTech Services',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _upiIdController,
                              decoration: InputDecoration(
                                labelText: 'UPI ID (VPA)',
                                hintText: 'e.g., protech@sbi',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _isEditingUpi
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingUpi = false;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                  ),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.blueGrey)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _saveUpiId,
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text('Save UPI Details'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditingUpi = true;
                                });
                              },
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              label: const Text('Change UPI ID', style: TextStyle(color: Colors.blueAccent)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
