#!/bin/bash

# This script creates a symbolic link to ensure assets are properly found
# It also rebuilds the asset catalog to ensure the app icon is recognized

# Navigate to the project directory
cd /Users/kimha/git/RoadToRehab/frontend/PTTracker

# Make sure Contents.json exists in all asset directories
mkdir -p PTTracker/Assets.xcassets
echo '{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}' > PTTracker/Assets.xcassets/Contents.json

# Create a symbolic link at the project root level in case that's where Xcode is looking
ln -sf PTTracker/Assets.xcassets Assets.xcassets

# Also create a symbolic link to ensure AppIcon is found in all possible locations
mkdir -p Assets.xcassets
cp -f PTTracker/Assets.xcassets/Contents.json Assets.xcassets/
ln -sf PTTracker/Assets.xcassets/AppIcon.appiconset Assets.xcassets/AppIcon.appiconset

# Touch the plist file to ensure changes are registered
touch PTTracker/Info.plist

echo "Asset catalog has been updated and symbolic links created."
echo "Please rebuild your project in Xcode." 