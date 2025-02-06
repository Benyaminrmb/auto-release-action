#!/bin/bash

# Script to update version numbers in documentation
# Save as .github/workflows/update-docs.sh

set -e

# Get Latest Tag
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)

# If no tags exist, create v0.0.1
if [ -z "$LATEST_TAG" ]; then
  echo "No tags found. Creating initial tag v0.0.1..."
  LATEST_TAG="v0.0.1"
  git tag -a "$LATEST_TAG" -m "Initial release"
  git push origin "$LATEST_TAG"
fi
VERSION=${LATEST_TAG#v}

echo "Updating documentation to version $VERSION..."

# Update version in README.md
# This uses perl for better in-place editing and regex support
perl -i -pe "s/(Benyaminrmb\/auto-release-action@v)\d+\.\d+\.\d+/\${1}$VERSION/g" README.md

# Check if there are changes
if git diff --quiet README.md; then
    echo "No version updates needed in documentation."
    exit 0
fi

# Commit and push changes
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

git add README.md
git commit -m "docs: update version references to $LATEST_TAG"
git push origin HEAD

echo "Documentation updated successfully to version $VERSION"