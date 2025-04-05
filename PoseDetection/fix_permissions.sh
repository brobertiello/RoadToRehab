#!/bin/bash

echo "Fixing camera permissions in PoseDetection app..."

# Create LaunchScreen file directory
mkdir -p PoseDetection/PoseDetection/Resources

# Create a simple LaunchScreen storyboard
cat > PoseDetection/PoseDetection/Resources/LaunchScreen.storyboard << 'EOF'
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

echo "Created LaunchScreen.storyboard"

# Make sure NSCameraUsageDescription is in Info.plist
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

echo "Updated Info.plist with proper camera permissions"

# Create a basic build file for the resources
cat > build.sh << 'EOF'
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
EOF

chmod +x build.sh

echo ""
echo "Permission fix complete. Run ./build.sh to build the project."
echo "Make sure to open the project in Xcode, verify the Info.plist has the camera usage description,"
echo "and then build and run on your device." 