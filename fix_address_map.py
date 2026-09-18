file_path = "shared_core/lib/widgets/address_selection_map.dart"
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace("await placemarkFromCoordinates(", "await Geocoding().placemarkFromCoordinates(")

with open(file_path, 'w') as f:
    f.write(content)
