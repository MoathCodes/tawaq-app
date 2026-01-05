#!/usr/bin/env python3
"""
Generates font entries for all 604 QCF4 page fonts plus the basmalah font
and updates the pubspec.yaml file.
"""

import os

def generate_font_entries():
    """Generate YAML entries for all 604 page fonts plus basmalah."""
    entries = []
    
    # Add basmalah font first
    entries.append("    - family: QCF4_BSML\n      fonts:\n        - asset: assets/otf_fonts/QCF4_BSML.otf")
    
    # Add all 604 page fonts
    for page in range(1, 605):
        padded = str(page).zfill(3)
        entries.append(f"    - family: QCF4_{padded}\n      fonts:\n        - asset: assets/otf_fonts/QCF4_{padded}.otf")
    
    return "\n".join(entries)

def update_pubspec(pubspec_path):
    """Update pubspec.yaml with the font entries."""
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Generate font entries
    font_entries = generate_font_entries()
    
    # Find the flutter: section and add fonts after assets
    new_lines = []
    in_flutter = False
    added_fonts = False
    
    for i, line in enumerate(lines):
        new_lines.append(line)
        
        # Check if we're entering flutter section
        if line.strip() == 'flutter:':
            in_flutter = True
            continue
        
        # Check if we've exited flutter section
        if in_flutter and line.strip() and not line.startswith(' ') and not line.startswith('\t'):
            in_flutter = False
        
        # If in flutter section and we see assets section ending, add fonts after
        if in_flutter and not added_fonts:
            # Check if next line exits assets or if this is end of assets
            if line.strip().startswith('- assets/'):
                # Check if next line is not an asset
                if i + 1 < len(lines):
                    next_line = lines[i + 1]
                    if not next_line.strip().startswith('-'):
                        # Add fonts section here
                        new_lines.append("\n  fonts:\n")
                        new_lines.append(font_entries + "\n")
                        added_fonts = True
                else:
                    # End of file, add fonts
                    new_lines.append("\n  fonts:\n")
                    new_lines.append(font_entries + "\n")
                    added_fonts = True
    
    # If we didn't add fonts yet, add at end of flutter section
    if not added_fonts:
        # Find last line of file and append
        new_lines.append("\n  fonts:\n")
        new_lines.append(font_entries + "\n")
    
    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    return True

def main():
    # Find pubspec.yaml (should be in parent directory of tool/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    pubspec_path = os.path.join(script_dir, '..', 'pubspec.yaml')
    
    if not os.path.exists(pubspec_path):
        print(f"Error: pubspec.yaml not found at {pubspec_path}")
        return
    
    print(f"Updating {pubspec_path}...")
    print("Adding 605 font families (1 basmalah + 604 page fonts)...")
    
    if update_pubspec(pubspec_path):
        print("Done! pubspec.yaml has been updated with all font entries.")
        print("\nNote: Run 'flutter pub get' to ensure the assets are recognized.")
    else:
        print("Failed to update pubspec.yaml")

if __name__ == "__main__":
    main()
