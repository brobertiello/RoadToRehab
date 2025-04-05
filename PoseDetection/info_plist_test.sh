#!/bin/bash

echo "Testing Info.plist configuration..."

# First check if Info.plist exists
if [ ! -f Info.plist ]; then
    echo "ERROR: Info.plist not found in the root directory"
    exit 1
fi

# Check if the camera usage description exists in the Info.plist
if grep -q "NSCameraUsageDescription" Info.plist; then
    echo "SUCCESS: NSCameraUsageDescription found in Info.plist"
else
    echo "ERROR: NSCameraUsageDescription not found in Info.plist"
    exit 1
fi

# Verify build settings reference the Info.plist
if grep -q "INFOPLIST_FILE" PoseDetection.xcconfig; then
    echo "SUCCESS: INFOPLIST_FILE setting found in PoseDetection.xcconfig"
    echo "  $(grep "INFOPLIST_FILE" PoseDetection.xcconfig)"
else
    echo "ERROR: INFOPLIST_FILE setting not found in PoseDetection.xcconfig"
    exit 1
fi

echo ""
echo "Info.plist looks good. Now check the following in Xcode:"
echo "1. Make sure 'Info.plist' is included in your target's 'Copy Bundle Resources' build phase"
echo "2. In Xcode, select the PoseDetection target, go to Build Settings, and search for 'Info.plist File'"
echo "3. Verify it points to 'Info.plist' (the root level one)"
echo ""
echo "After making these changes, clean the build folder (Product → Clean Build Folder) and try again." 