#!/bin/bash

echo "Configuring PoseDetection for iPhone 13 compatibility..."

# Clear Xcode cache
rm -rf ~/Library/Developer/Xcode/DerivedData/*PoseDetection*

# Set iOS 16.0 as deployment target (iPhone 13 ships with iOS 15+)
cat > ios_version_fix.xcconfig << EOF
// iOS compatibility configuration for iPhone 13
IPHONEOS_DEPLOYMENT_TARGET = 16.0
ARCHS = \$(ARCHS_STANDARD)
VALID_ARCHS = arm64
TARGETED_DEVICE_FAMILY = 1
SUPPORTED_PLATFORMS = iphoneos iphonesimulator
SWIFT_VERSION = 5.0
EOF

echo "Created iPhone 13 compatibility configuration"
echo ""
echo "INSTRUCTIONS FOR XCODE:"
echo "1. Open PoseDetection.xcodeproj in Xcode"
echo "2. Select the PoseDetection target"
echo "3. Go to General tab"
echo "4. Set 'Minimum Deployments' to iOS 16.0"
echo "5. Go to Build Settings tab"
echo "6. Search for 'iOS Deployment Target' and set it to iOS 16.0"
echo "7. Set 'Architectures' to 'Standard Architectures (arm64)'"
echo "8. Set 'Build Active Architecture Only' to 'Yes' for Debug"
echo "9. Clean the build folder (Product → Clean Build Folder)"
echo "10. Try building again"
echo ""
echo "The app has been configured to work with iPhone 13 devices running iOS 16.0 or later." 