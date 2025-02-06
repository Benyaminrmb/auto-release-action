#!/bin/bash

# Script to update version numbers in documentation
# Save as .github/workflows/update-docs.sh

set -e

# Get Latest Tag
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)
if [ -z "$LATEST_TAG" ]; then
  echo "No tags found. Using initial commit as base."
  LATEST_TAG=$(git rev-list --max-parents=0 HEAD)
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