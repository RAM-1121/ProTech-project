import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_data_provider.dart';

class TaskPendingDialog extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskPendingDialog({super.key, required this.task});

  @override
  State<TaskPendingDialog> createState() => _TaskPendingDialogState();
}

class _TaskPendingDialogState extends State<TaskPendingDialog> {
  final _reasonController = TextEditingController();
  // We'll mock image upload for now
  bool _imageUploaded = false;

  void _submit() async {
    if (_reasonController.text.isEmpty) return;

    final success = await context.read<ApiDataProvider>().updateTaskStatus(
      bookingId: widget.task['id'], 
      status: 'executive_pending', 
      pendingReason: _reasonController.text,
    );
    
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task marked as Pending')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update task')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as Pending'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for pending',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _imageUploaded = true);
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(_imageUploaded ? 'Image Uploaded' : 'Upload Image / Proof'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
