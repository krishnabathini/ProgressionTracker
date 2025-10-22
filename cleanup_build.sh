#!/bin/bash

# GitLifting SwiftData Macro Build Cleanup Script
# Fixes macro generation errors by cleaning all build caches

echo "🧹 GitLifting Build Cleanup Script"
echo "=================================="
echo ""

# Check if Xcode is running
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  WARNING: Xcode is currently running!"
    echo "   Please close Xcode before running this script for best results."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled. Please close Xcode and run again."
        exit 1
    fi
fi

echo "🔍 Step 1: Finding DerivedData folder..."
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

if [ -d "$DERIVED_DATA_PATH" ]; then
    echo "✅ Found: $DERIVED_DATA_PATH"
    
    # Find ProgressionTracker build folders
    PROGRESSION_FOLDERS=$(find "$DERIVED_DATA_PATH" -maxdepth 1 -name "ProgressionTracker-*" 2>/dev/null)
    
    if [ -n "$PROGRESSION_FOLDERS" ]; then
        echo "📁 Found ProgressionTracker build folders:"
        echo "$PROGRESSION_FOLDERS" | while read folder; do
            echo "   - $(basename "$folder")"
        done
        echo ""
        
        echo "🗑️  Step 2: Removing ProgressionTracker DerivedData..."
        echo "$PROGRESSION_FOLDERS" | while read folder; do
            rm -rf "$folder" 2>/dev/null && echo "   ✅ Removed: $(basename "$folder")" || echo "   ⚠️  Could not remove: $(basename "$folder")"
        done
    else
        echo "ℹ️  No ProgressionTracker build folders found (already clean)"
    fi
else
    echo "⚠️  DerivedData folder not found at expected location"
fi

echo ""
echo "🗑️  Step 3: Clearing Swift module cache..."
MODULE_CACHE="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
if [ -d "$MODULE_CACHE" ]; then
    rm -rf "$MODULE_CACHE" 2>/dev/null && echo "✅ Module cache cleared" || echo "⚠️  Could not clear module cache"
else
    echo "ℹ️  Module cache not found (already clean)"
fi

echo ""
echo "🗑️  Step 4: Clearing Xcode caches..."
XCODE_CACHE="$HOME/Library/Caches/com.apple.dt.Xcode"
if [ -d "$XCODE_CACHE" ]; then
    rm -rf "$XCODE_CACHE" 2>/dev/null && echo "✅ Xcode caches cleared" || echo "⚠️  Could not clear Xcode caches"
else
    echo "ℹ️  Xcode caches not found (already clean)"
fi

echo ""
echo "🗑️  Step 5: Clearing Swift PM cache..."
SWIFT_PM_CACHE="$HOME/Library/Caches/org.swift.swiftpm"
if [ -d "$SWIFT_PM_CACHE" ]; then
    rm -rf "$SWIFT_PM_CACHE" 2>/dev/null && echo "✅ Swift PM cache cleared" || echo "⚠️  Could not clear Swift PM cache"
else
    echo "ℹ️  Swift PM cache not found (already clean)"
fi

echo ""
echo "=================================="
echo "✅ Cleanup complete!"
echo ""
echo "📋 Next Steps:"
echo "   1. Open Xcode"
echo "   2. Product → Clean Build Folder (⇧⌘K)"
echo "   3. Product → Build (⌘B)"
echo "   4. Product → Run (⌘R)"
echo ""
echo "💡 Expected Result:"
echo "   - Build should succeed"
echo "   - No macro generation errors"
echo "   - App runs without crashes"
echo ""
echo "🎉 You're all set!"

