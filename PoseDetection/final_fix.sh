#!/bin/bash

echo "==== Comprehensive Info.plist Fix for PoseDetection App ===="

# 1. Make sure Info.plist exists and has the right content
echo "Regenerating Info.plist with correct permissions..."
cat > Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>MinimumOSVersion</key>
	<string>16.0</string>
	<key>NSCameraUsageDescription</key>
	<string>This app requires camera access to detect body poses</string>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>armv7</string>
		<string>arm64</string>
	</array>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
	</dict>
</dict>
</plist>
EOF

# 2. Clean up any duplicate Info.plist files
echo "Cleaning up duplicate Info.plist files..."
find PoseDetection -name "Info.plist" -not -path "./Info.plist" -delete

# 3. Make sure PoseDetection.xcconfig has the right INFOPLIST_FILE setting
echo "Updating PoseDetection.xcconfig..."
if grep -q "INFOPLIST_FILE" PoseDetection.xcconfig; then
    sed -i '' 's#INFOPLIST_FILE = .*#INFOPLIST_FILE = Info.plist#' PoseDetection.xcconfig
else
    echo "INFOPLIST_FILE = Info.plist" >> PoseDetection.xcconfig
fi

# 4. Create a dummy LaunchScreen.storyboard if it doesn't exist
echo "Creating LaunchScreen storyboard..."
mkdir -p PoseDetection/Resources
cat > PoseDetection/Resources/LaunchScreen.storyboard << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21507" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="21505"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <!--View Controller-->
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Pose Detection" textAlignment="natural" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="hKw-hx-ZL3">
                                <rect key="frame" x="99" y="409" width="195" height="34"/>
                                <fontDescription key="fontDescription" style="UICTFontTextStyleTitle1"/>
                                <nil key="textColor"/>
                                <nil key="highlightedColor"/>
                            </label>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                        <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="hKw-hx-ZL3" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="G9J-cg-Lju"/>
                            <constraint firstItem="hKw-hx-ZL3" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="gW1-Ie-Xwd"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userInteractionIdentifier="IBFirstResponder" objects="{665, 0}" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
</document>
EOF

# 5. Clear derived data
echo "Clearing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*PoseDetection*

echo ""
echo "==== COMPLETE INFO.PLIST FIX RESULTS ===="
echo "1. Info.plist regenerated with camera permission"
echo "2. PoseDetection.xcconfig updated to point to Info.plist"
echo "3. LaunchScreen.storyboard created"
echo "4. Duplicate Info.plist files removed"
echo "5. Xcode derived data cleared"
echo ""
echo "NEXT STEPS IN XCODE:"
echo "1. Open PoseDetection.xcodeproj"
echo "2. Select the PoseDetection target"
echo "3. Go to Build Phases"
echo "4. Expand 'Copy Bundle Resources' and make sure Info.plist is included"
echo "5. Go to Build Settings and search for 'Info.plist File'"
echo "6. Set it to 'Info.plist' (root level)"
echo "7. Clean the build folder (Product → Clean Build Folder)"
echo "8. Build and run the app" 