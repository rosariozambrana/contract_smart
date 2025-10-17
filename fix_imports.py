import os
import re

def fix_imports_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Get the relative depth from presentacion
    rel_path = os.path.relpath(filepath, 'lib/presentacion')
    depth = rel_path.count(os.sep)

    # Determine the correct path prefix based on depth
    if depth == 1:  # files in presentacion/ (like providers)
        providers_prefix = ''
        negocio_prefix = '../'
        datos_prefix = '../'
        widgets_prefix = ''
        screens_prefix = ''
    elif depth == 2:  # files in presentacion/screens/ or presentacion/widgets/
        providers_prefix = '../'
        negocio_prefix = '../../'
        datos_prefix = '../../'
        widgets_prefix = '../'
        screens_prefix = '../'
    elif depth >= 3:  # files in presentacion/screens/xxx/ or deeper
        providers_prefix = '../' * (depth - 1)
        negocio_prefix = '../' * depth
        datos_prefix = '../' * depth
        widgets_prefix = '../' * (depth - 1)
        screens_prefix = '../' * (depth - 1)

    # Fix imports
    # Fix models imports
    content = re.sub(r"import '\.\./models/", f"import '{negocio_prefix}negocio/models/", content)
    content = re.sub(r"import '\.\./\.\./models/", f"import '{negocio_prefix}negocio/models/", content)

    # Fix services/datos imports
    content = re.sub(r"import '\.\./services/", f"import '{datos_prefix}datos/", content)
    content = re.sub(r"import '\.\./\.\./services/", f"import '{datos_prefix}datos/", content)
    content = re.sub(r"import 'package:rentals/services/", f"import '{datos_prefix}datos/", content)

    # Fix providers imports
    content = re.sub(r"import '\.\./providers/", f"import '{providers_prefix}providers/", content)
    content = re.sub(r"import 'package:rentals/controllers_providers/", f"import '{providers_prefix}providers/", content)

    # Fix widgets imports
    content = re.sub(r"import '\.\./widgets/", f"import '{widgets_prefix}widgets/", content)

    # Fix components imports
    content = re.sub(r"import 'package:rentals/vista/components/", f"import '{screens_prefix}components/", content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
        return True
    return False

# Find all Dart files in presentacion
count = 0
for root, dirs, files in os.walk('lib/presentacion'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            if fix_imports_in_file(filepath):
                count += 1

print(f"\nTotal files fixed: {count}")
