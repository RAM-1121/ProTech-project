with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "showPopupMessage(context," in line and "maps" in line:
        lines[i] = "        showPopupMessage(context, 'Could not open maps');\n"
    if "showPopupMessage(context," in line and "dialer" in line:
        lines[i] = "        showPopupMessage(context, 'Could not open dialer');\n"
    if ");" in line and "        );" in line and "maps" in lines[i-1]:
        lines[i] = ""
    if ");" in line and "        );" in line and "dialer" in lines[i-1]:
        lines[i] = ""

with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'w') as f:
    f.writelines(lines)
