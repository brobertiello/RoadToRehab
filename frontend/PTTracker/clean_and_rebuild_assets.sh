#!/bin/bash

# This script completely rebuilds the app icons from scratch
# Run this if you're still having issues with the app icon

# Navigate to the project directory
cd /Users/kimha/git/RoadToRehab/frontend/PTTracker

# Backup the original icon files
echo "Backing up original icon files..."
mkdir -p icon_backup
cp -f PTTracker/Assets.xcassets/web-app-manifest-512x512.png icon_backup/

# Clean all icon files and recreate from scratch
echo "Cleaning icon files..."
rm -rf PTTracker/Assets.xcassets/AppIcon.appiconset
mkdir -p PTTracker/Assets.xcassets/AppIcon.appiconset

# Create a proper Contents.json
echo "Creating proper Contents.json..."
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

# Create the app icon files
echo "Generating app icon files..."
SOURCE_ICON="PTTracker/Assets.xcassets/web-app-manifest-512x512.png"
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

echo "App icon files regenerated."

# Update the Info.plist to force icon refresh
echo "Updating Info.plist to ensure icon is referenced..."
plutil -replace CFBundleIconName -string "AppIcon" PTTracker/Info.plist 2>/dev/null || echo "Could not add CFBundleIconName to Info.plist, but this is not critical."

echo "Asset catalog has been completely rebuilt."
echo "Please clean and rebuild your project in Xcode."
echo "Command: Product > Clean Build Folder, then Build" 