file_path = "shared_core/lib/services/api_service.dart"
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace("import 'dart:io' show Platform;\n", "")
content = content.replace("    if (!kIsWeb && Platform.isAndroid) {\n      return 'http://192.168.1.7:3000';\n    }\n    return 'http://192.168.1.7:3000';", "    return 'http://192.168.1.7:3000';")

with open(file_path, 'w') as f:
    f.write(content)
