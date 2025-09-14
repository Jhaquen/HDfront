#!/bin/bash

# --- User Configuration ---
BRANCH_NAME="master"
REMOTE_NAME="origin"

# --- Script Logic ---

# Check if a commit message was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <commit_message>"
    exit 1
fi

# Store the commit message from the first command-line argument
COMMIT_MESSAGE="$1"

echo "--- Starting Git Automation ---"

# Step 1: Get the last tag number and increment it
LAST_TAG=$(git tag --sort=-committerdate | grep -E '^v1\.0\.[0-9]+$' | head -n 1)

if [ -z "$LAST_TAG" ]; then
    # No existing tags, start at 0
    NEW_TAG_NUMBER=0
else
    # Extract the number and increment it
    TAG_NUMBER=$(echo "$LAST_TAG" | sed 's/v1\.0\.//')
    NEW_TAG_NUMBER=$((TAG_NUMBER + 1))
fi

NEW_TAG="v1.0.$NEW_TAG_NUMBER"
NEW_VERSION="1.0.$NEW_TAG_NUMBER+1"

# Step 2: Update pubspec.yaml with the new version
echo "Updating pubspec.yaml to version: $NEW_VERSION..."
sed -i "s/version: .*/version: $NEW_VERSION/" pubspec.yaml

# Step 3: Add all changes
echo "Adding all changes..."
git add .

# Step 4: Commit changes with the provided message
echo "Committing with message: '$COMMIT_MESSAGE'..."
git commit -m "$COMMIT_MESSAGE"

# Step 5: Push the commit to the remote branch
echo "Pushing to $REMOTE_NAME/$BRANCH_NAME..."
git push "$REMOTE_NAME" "$BRANCH_NAME"

# Step 6: Create and push the new tag
echo "Creating new tag: $NEW_TAG..."
git tag "$NEW_TAG"

echo "Pushing new tag to remote..."
git push "$REMOTE_NAME" "$NEW_TAG"

echo "--- Git Automation Complete ---"
