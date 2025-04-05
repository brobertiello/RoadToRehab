#!/bin/bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*PoseDetection*

# Tell the user what to do
echo "INSTRUCTIONS FOR CAMERA PERMISSIONS:"
echo "1. Open PoseDetection.xcodeproj in Xcode"
echo "2. Go to the Info.plist file (it should appear in the Project Navigator)"
echo "3. Verify that NSCameraUsageDescription exists with a proper description"
echo "4. Build and run the app"
echo "5. When prompted, allow camera access"
