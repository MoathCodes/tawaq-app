#!/bin/bash
# migrate_spacing.sh - Migrate magic values to design tokens
# Run from project root: bash migrate_spacing.sh

set -e

LIB_DIR="lib"
IMPORT_LINE="import 'package:tawaq/theme/theme.dart';"

# Files to skip (already migrated or special)
SKIP_FILES=(
  "lib/theme/"
  "lib/gen/"
  "lib/l10n/"
  "lib/hive/"
  ".freezed.dart"
  ".g.dart"
)

should_skip() {
  local file="$1"
  for skip in "${SKIP_FILES[@]}"; do
    if [[ "$file" == *"$skip"* ]]; then
      return 0
    fi
  done
  return 1
}

add_import_if_needed() {
  local file="$1"
  if ! grep -q "package:tawaq/theme/theme.dart" "$file"; then
    # Find the last import line and add after it
    if grep -q "^import " "$file"; then
      # Add import after the last existing import
      sed -i "/^import /{ :a; n; /^import /ba; i\\$IMPORT_LINE
}" "$file"
    fi
  fi
}

echo "=== Migrating SizedBox height values ==="

# SizedBox(height: 4) -> SizedBox(height: AppSpacing.xs)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(height: 4)" "$file"; then
    echo "  Updating: $file (height: 4 -> xs)"
    sed -i 's/const SizedBox(height: 4)/SizedBox(height: AppSpacing.xs)/g' "$file"
    sed -i 's/SizedBox(height: 4)/SizedBox(height: AppSpacing.xs)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(height: 8) -> SizedBox(height: AppSpacing.sm)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(height: 8)" "$file"; then
    echo "  Updating: $file (height: 8 -> sm)"
    sed -i 's/const SizedBox(height: 8)/SizedBox(height: AppSpacing.sm)/g' "$file"
    sed -i 's/SizedBox(height: 8)/SizedBox(height: AppSpacing.sm)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(height: 12) -> SizedBox(height: AppSpacing.md)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(height: 12)" "$file"; then
    echo "  Updating: $file (height: 12 -> md)"
    sed -i 's/const SizedBox(height: 12)/SizedBox(height: AppSpacing.md)/g' "$file"
    sed -i 's/SizedBox(height: 12)/SizedBox(height: AppSpacing.md)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(height: 16) -> SizedBox(height: AppSpacing.lg)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(height: 16)" "$file"; then
    echo "  Updating: $file (height: 16 -> lg)"
    sed -i 's/const SizedBox(height: 16)/SizedBox(height: AppSpacing.lg)/g' "$file"
    sed -i 's/SizedBox(height: 16)/SizedBox(height: AppSpacing.lg)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(height: 24) -> SizedBox(height: AppSpacing.xl)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(height: 24)" "$file"; then
    echo "  Updating: $file (height: 24 -> xl)"
    sed -i 's/const SizedBox(height: 24)/SizedBox(height: AppSpacing.xl)/g' "$file"
    sed -i 's/SizedBox(height: 24)/SizedBox(height: AppSpacing.xl)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(height: 32) -> SizedBox(height: AppSpacing.xxl)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(height: 32)" "$file"; then
    echo "  Updating: $file (height: 32 -> xxl)"
    sed -i 's/const SizedBox(height: 32)/SizedBox(height: AppSpacing.xxl)/g' "$file"
    sed -i 's/SizedBox(height: 32)/SizedBox(height: AppSpacing.xxl)/g' "$file"
    add_import_if_needed "$file"
  fi
done

echo ""
echo "=== Migrating SizedBox width values ==="

# SizedBox(width: 4) -> SizedBox(width: AppSpacing.xs)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(width: 4)" "$file"; then
    echo "  Updating: $file (width: 4 -> xs)"
    sed -i 's/const SizedBox(width: 4)/SizedBox(width: AppSpacing.xs)/g' "$file"
    sed -i 's/SizedBox(width: 4)/SizedBox(width: AppSpacing.xs)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(width: 8) -> SizedBox(width: AppSpacing.sm)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(width: 8)" "$file"; then
    echo "  Updating: $file (width: 8 -> sm)"
    sed -i 's/const SizedBox(width: 8)/SizedBox(width: AppSpacing.sm)/g' "$file"
    sed -i 's/SizedBox(width: 8)/SizedBox(width: AppSpacing.sm)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(width: 12) -> SizedBox(width: AppSpacing.md)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(width: 12)" "$file"; then
    echo "  Updating: $file (width: 12 -> md)"
    sed -i 's/const SizedBox(width: 12)/SizedBox(width: AppSpacing.md)/g' "$file"
    sed -i 's/SizedBox(width: 12)/SizedBox(width: AppSpacing.md)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# SizedBox(width: 16) -> SizedBox(width: AppSpacing.lg)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "SizedBox(width: 16)" "$file"; then
    echo "  Updating: $file (width: 16 -> lg)"
    sed -i 's/const SizedBox(width: 16)/SizedBox(width: AppSpacing.lg)/g' "$file"
    sed -i 's/SizedBox(width: 16)/SizedBox(width: AppSpacing.lg)/g' "$file"
    add_import_if_needed "$file"
  fi
done

echo ""
echo "=== Migrating EdgeInsets.all values ==="

# EdgeInsets.all(4) -> EdgeInsets.all(AppSpacing.xs)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "EdgeInsets.all(4)" "$file"; then
    echo "  Updating: $file (all(4) -> xs)"
    sed -i 's/const EdgeInsets.all(4)/EdgeInsets.all(AppSpacing.xs)/g' "$file"
    sed -i 's/EdgeInsets.all(4)/EdgeInsets.all(AppSpacing.xs)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# EdgeInsets.all(8) -> EdgeInsets.all(AppSpacing.sm)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "EdgeInsets.all(8)" "$file"; then
    echo "  Updating: $file (all(8) -> sm)"
    sed -i 's/const EdgeInsets.all(8)/EdgeInsets.all(AppSpacing.sm)/g' "$file"
    sed -i 's/EdgeInsets.all(8)/EdgeInsets.all(AppSpacing.sm)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# EdgeInsets.all(12) -> EdgeInsets.all(AppSpacing.md)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "EdgeInsets.all(12)" "$file"; then
    echo "  Updating: $file (all(12) -> md)"
    sed -i 's/const EdgeInsets.all(12)/EdgeInsets.all(AppSpacing.md)/g' "$file"
    sed -i 's/EdgeInsets.all(12)/EdgeInsets.all(AppSpacing.md)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# EdgeInsets.all(16) -> EdgeInsets.all(AppSpacing.lg)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "EdgeInsets.all(16)" "$file"; then
    echo "  Updating: $file (all(16) -> lg)"
    sed -i 's/const EdgeInsets.all(16)/EdgeInsets.all(AppSpacing.lg)/g' "$file"
    sed -i 's/EdgeInsets.all(16)/EdgeInsets.all(AppSpacing.lg)/g' "$file"
    add_import_if_needed "$file"
  fi
done

# EdgeInsets.all(24) -> EdgeInsets.all(AppSpacing.xl)
find "$LIB_DIR" -name "*.dart" -type f | while read -r file; do
  should_skip "$file" && continue
  if grep -q "EdgeInsets.all(24)" "$file"; then
    echo "  Updating: $file (all(24) -> xl)"
    sed -i 's/const EdgeInsets.all(24)/EdgeInsets.all(AppSpacing.xl)/g' "$file"
    sed -i 's/EdgeInsets.all(24)/EdgeInsets.all(AppSpacing.xl)/g' "$file"
    add_import_if_needed "$file"
  fi
done

echo ""
echo "=== Running dart fix to clean up ==="
dart fix --apply

echo ""
echo "=== Migration complete! ==="
echo "Run 'flutter analyze' to check for any issues."
