#!/bin/bash

# This script uses apple-touch-icon.png as the source for all app icons
# This is often a better choice for iOS app icons

# Navigate to the project directory
cd /Users/kimha/git/RoadToRehab/frontend/PTTracker

# Backup the existing icons
echo "Backing up existing icon files..."
mkdir -p icon_backup/AppIcon.appiconset
cp -f PTTracker/Assets.xcassets/AppIcon.appiconset/* icon_backup/AppIcon.appiconset/ 2>/dev/null

# Clean and create directory
echo "Setting up icon directories..."
rm -rf PTTracker/Assets.xcassets/AppIcon.appiconset
mkdir -p PTTracker/Assets.xcassets/AppIcon.appiconset

# Create a proper Contents.json
echo "Creating Contents.json..."
cat > PTTracker/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOL'
{
  "images" : [
    {
      "filename" : "AppIcon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-20.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOL

# Use apple-touch-icon.png as source
echo "Generating icons from apple-touch-icon.png..."
SOURCE_ICON="PTTracker/Assets.xcassets/apple-touch-icon.png"
OUTPUT_DIR="PTTracker/Assets.xcassets/AppIcon.appiconset"

# Generate iPhone icons
sips -z 40 40 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-20@2x.png"
sips -z 60 60 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-20@3x.png"
sips -z 58 58 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-29@2x.png"
sips -z 87 87 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-29@3x.png"
sips -z 80 80 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-40@2x.png"
sips -z 120 120 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-40@3x.png"
sips -z 120 120 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-60@2x.png"
sips -z 180 180 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-60@3x.png"

# Generate iPad icons
sips -z 20 20 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-20.png"
sips -z 29 29 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-29.png"
sips -z 40 40 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-40.png"
sips -z 76 76 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-76.png"
sips -z 152 152 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-76@2x.png"
sips -z 167 167 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-83.5@2x.png"

# Generate App Store icon
sips -z 1024 1024 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-1024.png"

# Update Contents.json in the root Assets directory
echo '{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}' > PTTracker/Assets.xcassets/Contents.json

# Also create symbolic links for better compatibility
ln -sf PTTracker/Assets.xcassets/AppIcon.appiconset Assets.xcassets/AppIcon.appiconset 2>/dev/null

# Touch the Info.plist to ensure changes are registered
touch PTTracker/Info.plist

echo "App icons have been regenerated using apple-touch-icon.png"
echo "Please clean and rebuild your project in Xcode:"
echo "Product > Clean Build Folder, then Build" 