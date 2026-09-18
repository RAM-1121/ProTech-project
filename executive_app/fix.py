import re

def fix():
    with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'r') as f:
        content = f.read()

    # The sed command replaced `)),` with `),`
    # We can't just blindly replace `),` with `)),`.
    # Let's count open/close parens.
    lines = content.split('\n')
    for i in range(len(lines)):
        # Let's just fix it manually for the known ones:
        if 'showPopupMessage(context,' in lines[i]:
            lines[i] = lines[i].replace("showPopupMessage(context,", "showPopupMessage(context,")
            # this is already on its own line
        
        # fix line 56
        if "'Task updated successfully')," in lines[i]:
            lines[i] = "          'Task updated successfully');"
        
        if "'Failed to update task')," in lines[i]:
            lines[i] = "          'Failed to update task');"

    # We need a robust parenthesis fixer or I can just fix it line by line based on dart format errors.
    with open('/Users/soumyth/Documents/AC/executive_app/lib/screens/task_detail_screen.dart', 'w') as f:
        f.write('\n'.join(lines))

fix()
