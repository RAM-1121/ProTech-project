with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'style: const TextStyle(fontSize: 16)),' in line and 'Expanded(' in lines[i-1]:
        lines[i] = line.replace('16)),', '16))),')
    if "const Text('Task Details'," in line:
        lines[i] = line.replace("fontWeight: FontWeight.bold),", "fontWeight: FontWeight.bold)),")
    if "color: theme.colorScheme.onSurface.withValues(alpha: 0.1)," in line:
        lines[i] = line.replace("0.1),", "0.1)),")
    if "Text('Type: ${_task.complaintType}'," in line:
        lines[i] = line.replace("fontWeight.bold),", "fontWeight.bold)),")

with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'w') as f:
    f.writelines(lines)

