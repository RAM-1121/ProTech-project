with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "TaskPendingScreen(taskId: _task.id)," in line:
        lines[i] = line.replace("id),", "id)),")
    if "PaymentScreen(workOrder: _task)," in line:
        lines[i] = line.replace("_task),", "_task)),")
    if "borderRadius: BorderRadius.circular(16)," in line:
        lines[i] = line.replace("16),", "16)),")

    if "'Task updated successfully');" in line:
        lines[i] = ""
    if "errorMsg)," in line:
        lines[i] = ""
    if ");" in line and "if (mounted) {" in lines[i-3]:
        lines[i] = "        showPopupMessage(context, 'Task updated successfully');\n"
    if ");" in line and "if (mounted) {" in lines[i-4] and "errorMsg" in lines[i-2]: # wait this is messy
        pass

with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'w') as f:
    f.writelines(lines)
