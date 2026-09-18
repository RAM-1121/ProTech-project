import re
import glob

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # The regex to match: ScaffoldMessenger.of(context).showSnackBar( ... SnackBar(content: Text( ... )), ... );
    # Some have `const SnackBar`, some don't.
    # Text('...') or Text(variable)
    
    # regex for single line or multi line
    # re.DOTALL to match across lines
    pattern = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(\s*content:\s*Text\((.*?)\)\s*\)\s*,\s*\);"
    
    if re.search(pattern, content, flags=re.DOTALL):
        # We need to add the import if it's not there
        if "import '../utils/popup_utils.dart';" not in content and "import 'package:flutter/material.dart';" in content:
            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../utils/popup_utils.dart';")
        
        # Replace
        new_content = re.sub(pattern, r"showPopupMessage(context, \1);", content, flags=re.DOTALL)
        
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        # Maybe it's formatted differently?
        pattern2 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(content:\s*Text\((.*?)\)\)\s*\);"
        if re.search(pattern2, content, flags=re.DOTALL):
            if "import '../utils/popup_utils.dart';" not in content and "import 'package:flutter/material.dart';" in content:
                content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../utils/popup_utils.dart';")
            new_content = re.sub(pattern2, r"showPopupMessage(context, \1);", content, flags=re.DOTALL)
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f"Updated {filepath} (pattern 2)")
        else:
            # Maybe SnackBar(content: Text(msg)) where it doesn't end with `,);` but `);`
            pass

files = glob.glob('/Users/soumyth/Documents/AC/executive_app/lib/screens/*.dart')
for file in files:
    if 'task_detail_screen' in file:
        continue # handled manually
    process_file(file)

