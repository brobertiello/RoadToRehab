#!/bin/bash

echo "Setting up build for physical device..."

# Create a specific build configuration for physical device
mkdir -p configs
cat > configs/device_build.xcconfig << EOF
// Device-specific build settings
ARCHS = \$(ARCHS_STANDARD)
VALID_ARCHS = arm64 arm64e
ONLY_ACTIVE_ARCH = YES

// Deployment settings
IPHONEOS_DEPLOYMENT_TARGET = 16.0
TARGETED_DEVICE_FAMILY = 1

// Build settings
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
SWIFT_COMPILATION_MODE = wholemodule

// Info.plist
INFOPLIST_FILE = Info.plist
EOF

echo "Created device build configuration"
echo ""
echo "In Xcode:"
echo "1. Open your project"
echo "2. Click on 'PoseDetection' target"
echo "3. Go to 'Build Settings' tab"
echo "4. Set 'Build Active Architecture Only' to YES for Debug"
echo "5. Set 'Architectures' to 'Standard Architectures (arm64)' for all configurations"
echo "6. Clean the build folder and rebuild"
echo ""
echo "If you still have issues, try running the app on a simulator first and then on the device." 