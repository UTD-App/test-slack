#!/bin/bash
# Syncs audio-room changes from test-slack to UTD-App/audio-room repo (test branch)

SOURCE="c:/Users/CONNECT/StudioProjects/test-slack/flutter/packages/audio-room"
TARGET="c:/Users/CONNECT/StudioProjects/audio-room-sync"

echo "=== Syncing audio-room ==="

cd "$TARGET"
git fetch origin 2>/dev/null
git checkout test 2>/dev/null || git checkout -b test

# Clean old files (keep .git)
find "$TARGET" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy new files
cp -r "$SOURCE"/* "$TARGET"/
cp -r "$SOURCE"/.[!.]* "$TARGET"/ 2>/dev/null

# Stage and push
git add -A
echo ""
git status --short
echo ""
echo "=== Pushing to origin/test ==="
git commit -m "sync: update from test-slack"
git push -u origin test

echo "=== Done ==="
