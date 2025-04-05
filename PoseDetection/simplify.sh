#!/bin/bash

echo "Simplifying project for easy building..."

# Remove any cache files
rm -rf ~/Library/Developer/Xcode/DerivedData/*PoseDetection*

# Create basic architecture settings
cat > arch_fix.xcconfig << EOF
ARCHS = \$(ARCHS_STANDARD)
VALID_ARCHS = arm64
ONLY_ACTIVE_ARCH = YES
EXCLUDED_ARCHS =
EOF

echo "Created architecture settings"
echo ""
echo "INSTRUCTIONS:"
echo "1. Open PoseDetection.xcodeproj in Xcode"
echo "2. Select the PoseDetection target"
echo "3. In Build Settings tab, do the following:"
echo "   - Set 'Architectures' to 'Standard Architectures (arm64)'"
echo "   - Set 'Build Active Architecture Only' to 'Yes'"
echo "   - Under 'Excluded Architectures', delete any values (leave empty)"
echo "   - Set 'Valid Architectures' to 'arm64'"
echo "4. Clean build folder (Product → Clean Build Folder)"
echo "5. Run on device"
echo ""
echo "This is now a super simple app with just one button that opens a placeholder camera screen." 