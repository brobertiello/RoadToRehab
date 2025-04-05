#!/bin/bash

# Clear Xcode DerivedData which might have cached incorrect settings
echo "Clearing Xcode derived data for PoseDetection..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*PoseDetection*

# Remove any stray Info.plist copies
echo "Removing duplicated Info.plist files..."
find . -name "Info.plist" -not -path "./Info.plist" -delete
find . -name "PoseDetection-Info.plist" -delete

# Create a new build folder with proper architecture settings
echo "Setting up proper architecture settings..."
mkdir -p build
cat > build/architectures.xcconfig << EOF
ARCHS = \$(ARCHS_STANDARD)
VALID_ARCHS = arm64 arm64e
ONLY_ACTIVE_ARCH = YES
EOF

echo "Clean completed. Now in Xcode:"
echo "1. Select the PoseDetection target"
echo "2. Go to Build Settings"
echo "3. Set 'Architectures' to 'Standard Architectures (arm64)'"
echo "4. Set 'Build Active Architecture Only' to 'Yes' for Debug"
echo "5. Clean build folder and rebuild" 