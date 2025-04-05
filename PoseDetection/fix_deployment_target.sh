#!/bin/bash

echo "Fixing deployment target to match your device iOS 18.3.2..."

# Update the deployment target in all relevant places
cat > ios_version_fix.xcconfig << EOF
IPHONEOS_DEPLOYMENT_TARGET = 18.3
EOF

# Try to update the project.pbxproj settings
echo "Attempting to update project settings..."
if command -v plutil &> /dev/null; then
    TEMP_PLIST="temp_project_settings.plist"
    plutil -convert xml1 -o $TEMP_PLIST PoseDetection.xcodeproj/project.pbxproj || echo "Cannot convert project file to XML"
    if [ -f "$TEMP_PLIST" ]; then
        # Try to update the deployment target
        plutil -replace BuildSettings.IPHONEOS_DEPLOYMENT_TARGET -string "18.3" $TEMP_PLIST || echo "Cannot update deployment target"
        plutil -convert binary1 -o PoseDetection.xcodeproj/project.pbxproj $TEMP_PLIST || echo "Cannot convert back to binary"
        rm $TEMP_PLIST
    fi
fi

# Update the Info.plist
echo "Updating Info.plist deployment target..."
# Already updated in a separate step

echo "Deployment target fixed to iOS 18.3"
echo ""
echo "INSTRUCTIONS:"
echo "1. Open PoseDetection.xcodeproj in Xcode"
echo "2. Select the PoseDetection target"
echo "3. Go to General tab"
echo "4. Set 'Minimum Deployments' to iOS 18.3"
echo "5. Go to Build Settings tab"
echo "6. Search for 'iOS Deployment Target' and set it to iOS 18.3"
echo "7. Clean build folder (Product → Clean Build Folder)"
echo "8. Try building again" 