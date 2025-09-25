#!/bin/bash

# Script to stow all dotfile configurations
# Run this from your dotfiles directory

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔗 Stowing all dotfile configurations..."
echo "Working directory: $(pwd)"
echo

# Get all directories (excluding hidden ones like .git)
PACKAGES=$(find . -maxdepth 1 -type d ! -name ".*" ! -name "." | sed 's|./||' | sort)

if [ -z "$PACKAGES" ]; then
    echo "❌ No packages found to stow!"
    exit 1
fi

echo "Found packages to stow:"
for package in $PACKAGES; do
    echo "  - $package"
done
echo

# Stow each package
success_count=0
error_count=0
errors=()

for package in $PACKAGES; do
    echo -n "Stowing $package... "
    
    if stow "$package" 2>/dev/null; then
        echo "✅ Success"
        ((success_count++))
    else
        echo "❌ Failed"
        ((error_count++))
        errors+=("$package")
        
        # Show the error details
        echo "  Error details:"
        stow "$package" 2>&1 | sed 's/^/    /'
        echo
    fi
done

echo
echo "📊 Summary:"
echo "  ✅ Successfully stowed: $success_count packages"
echo "  ❌ Failed to stow: $error_count packages"

if [ ${#errors[@]} -gt 0 ]; then
    echo
    echo "❌ Packages that failed:"
    for error in "${errors[@]}"; do
        echo "  - $error"
    done
    echo
    echo "💡 Tips for resolving conflicts:"
    echo "  - Use 'stow --adopt <package>' to adopt existing files"
    echo "  - Use 'stow -D <package>' to unstow first, then restow"
    echo "  - Manually resolve conflicts and re-run this script"
fi

echo
echo "🎉 Stowing complete!"