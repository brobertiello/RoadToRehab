# Pose Detection iOS App

This iOS application uses Apple's Vision framework to detect body poses using the device's front camera.

## Features
- Real-time body pose detection
- Visual overlay of detected body joints and connections
- Simple interface with one-tap activation

## Requirements
- iOS 18.3+
- Xcode 16.0+
- iPhone with front camera (development mode enabled)

## Installation and Setup

1. Clone the repository
2. Run `./clean.sh` to clear any cached build data and set up proper architectures
3. Open `PoseDetection.xcodeproj` in Xcode
4. **Important**: In Xcode, go to the project navigator, select the PoseDetection project, then select the PoseDetection target
5. Go to Build Settings and make these changes:
   - Info.plist File: Set to `Info.plist` (the top-level Info.plist)
   - Architectures: Set to "Standard Architectures (arm64)"
   - Build Active Architecture Only: Set to "Yes" for Debug
   - Valid Architectures: Set to "arm64 arm64e" 
6. Connect your iPhone (with development mode enabled and iOS 18.3 or later)
7. Clean the build folder (Product → Clean Build Folder)
8. Build and run the application

## Troubleshooting Build Issues

### For architecture errors ("doesn't support any of PoseDetection's architectures"):

1. Run the included `./clean.sh` script
2. In Xcode's Build Settings for the PoseDetection target:
   - Set "Architectures" to "Standard Architectures (arm64)"
   - Set "Build Active Architecture Only" to "Yes" for Debug
   - Set "Valid Architectures" to "arm64 arm64e"
3. Clean build folder and try again

### For Info.plist errors:

1. Run the included `./clean.sh` script
2. In Xcode, select Product → Clean Build Folder
3. Make sure you only have one Info.plist file at the root level
4. Check the Build Settings to ensure INFOPLIST_FILE is set to Info.plist
5. If needed, manually delete the DerivedData folder: 
   `rm -rf ~/Library/Developer/Xcode/DerivedData/*PoseDetection*`

## Usage

1. Launch the app on your iPhone
2. Tap the "Start Detection" button
3. Grant camera permissions when prompted
4. Position yourself within the camera view
5. The app will display a skeleton overlay on detected body parts
6. Tap the X button to return to the main screen

## Technical Implementation

This app uses:
- SwiftUI for the user interface
- AVFoundation for camera access
- **Vision framework** for body pose detection via `VNDetectHumanBodyPoseRequest`

## Privacy

This application processes all pose detection on-device. No camera data or detection results are sent to external servers. 