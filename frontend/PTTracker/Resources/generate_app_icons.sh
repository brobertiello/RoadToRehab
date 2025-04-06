#!/bin/bash

# This script generates all the required iOS app icon sizes from a source png file
# Usage: ./generate_app_icons.sh source_icon.png

SOURCE_ICON=$1
OUTPUT_DIR="/Users/kimha/git/RoadToRehab/frontend/PTTracker/PTTracker/Assets.xcassets/AppIcon.appiconset"

if [ -z "$SOURCE_ICON" ]; then
  echo "Please provide the source icon path."
  echo "Usage: ./generate_app_icons.sh source_icon.png"
  exit 1
fi

if [ ! -f "$SOURCE_ICON" ]; then
  echo "Source icon file not found: $SOURCE_ICON"
  exit 1
fi

# Make sure the output directory exists
mkdir -p "$OUTPUT_DIR"

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
# Already generated: AppIcon-20@2x.png
sips -z 29 29 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-29.png"
# Already generated: AppIcon-29@2x.png
sips -z 40 40 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-40.png"
# Already generated: AppIcon-40@2x.png
sips -z 76 76 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-76.png"
sips -z 152 152 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-76@2x.png"
sips -z 167 167 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-83.5@2x.png"

# Generate App Store icon
sips -z 1024 1024 "$SOURCE_ICON" --out "${OUTPUT_DIR}/AppIcon-1024.png"

echo "App icons generated successfully in $OUTPUT_DIR" 