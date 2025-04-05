#!/bin/bash

echo "Fixing architecture settings for PoseDetection..."

# Create a temporary xcconfig file with the right architecture settings
cat > arch_fix.xcconfig << EOF
ARCHS = \$(ARCHS_STANDARD)
VALID_ARCHS = arm64 arm64e
ONLY_ACTIVE_ARCH = YES
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
BUILD_LIBRARY_FOR_DISTRIBUTION = YES
EOF

echo "Created architecture configuration file."
echo ""
echo "INSTRUCTIONS:"
echo "=============="
echo "1. Open the PoseDetection.xcodeproj in Xcode"
echo "2. Select the PoseDetection target"
echo "3. Go to Build Settings tab" 
echo "4. Click the + button in the top-left"
echo "5. Select 'Add User-Defined Setting'"
echo "6. Set name to ARCHS and value to \$(ARCHS_STANDARD)"
echo "7. Add another setting with name VALID_ARCHS and value arm64 arm64e"
echo "8. Clean the build (Product → Clean Build Folder)"
echo "9. Try building again"
echo ""
echo "If you still see architecture errors, try building for a different device." 