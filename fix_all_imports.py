import os
import re

def get_depth_from_screens(filepath):
    """Calculate depth from presentacion/screens/"""
    if 'presentacion\\screens\\' in filepath or 'presentacion/screens/' in filepath:
        parts = filepath.replace('\\', '/').split('presentacion/screens/')[1]
        return parts.count('/')
    return 0

def fix_imports(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    depth = get_depth_from_screens(filepath)

    if depth == 0:
        return False  # Not in screens

    # Calculate correct prefixes based on depth
    # depth 1: screens/auth/file.dart -> ../../ for providers, ../../../ for negocio
    # depth 2: screens/home_cliente/contratos/file.dart -> ../../../ for providers, ../../../../ for negocio
    providers_prefix = '../' * (depth + 1)
    negocio_prefix = '../' * (depth + 2)
    datos_prefix = '../' * (depth + 2)
    widgets_prefix = '../' * (depth + 1)

    # Fix providers imports
    content = re.sub(r"import '\.\./providers/", f"import '{providers_prefix}providers/", content)
    content = re.sub(r"import '\.\./\.\./providers/", f"import '{providers_prefix}providers/", content)
    content = re.sub(r"import 'package:rentals/controllers_providers/", f"import '{providers_prefix}providers/", content)

    # Fix negocio/models imports
    content = re.sub(r"import '\.\./\.\./negocio/models/", f"import '{negocio_prefix}negocio/models/", content)
    content = re.sub(r"import '\.\./\.\./\.\./negocio/models/", f"import '{negocio_prefix}negocio/models/", content)

    # Fix datos imports
    content = re.sub(r"import '\.\./\.\./datos/", f"import '{datos_prefix}datos/", content)
    content = re.sub(r"import '\.\./\.\./\.\./datos/", f"import '{datos_prefix}datos/", content)
    content = re.sub(r"import 'package:rentals/services/", f"import '{datos_prefix}datos/", content)

    # Fix widgets imports
    content = re.sub(r"import '\.\./widgets/", f"import '{widgets_prefix}widgets/", content)
    content = re.sub(r"import '\.\./\.\./widgets/", f"import '{widgets_prefix}widgets/", content)

    # Fix components imports (same level as screens)
    content = re.sub(r"import 'package:rentals/vista/components/", "import '../components/", content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
        return True
    return False

# Fix all files in presentacion/screens
count = 0
for root, dirs, files in os.walk('lib/presentacion/screens'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            if fix_imports(filepath):
                count += 1

print(f"\nTotal files fixed: {count}")
