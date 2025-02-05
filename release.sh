#!/bin/bash

set -e

# Get Latest Tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Latest tag: $LATEST_TAG"

# Determine Next Version
VERSION=${LATEST_TAG#v}
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
PATCH=$(echo "$VERSION" | cut -d. -f3)

# Check all commits since last tag for version bumping
COMMITS=$(git log $LATEST_TAG..HEAD --pretty=format:"%s")

BREAKING_CHANGE=false
NEW_FEATURE=false

while IFS= read -r COMMIT; do
  if echo "$COMMIT" | grep -iqE "BREAKING[ -]CHANGE|!:"; then
    BREAKING_CHANGE=true
    break
  elif echo "$COMMIT" | grep -iq "feat:"; then
    NEW_FEATURE=true
  fi
done <<< "$COMMITS"

if [ "$BREAKING_CHANGE" = true ]; then
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
elif [ "$NEW_FEATURE" = true ]; then
  MINOR=$((MINOR + 1))
  PATCH=0
else
  PATCH=$((PATCH + 1))
fi

NEW_TAG="v$MAJOR.$MINOR.$PATCH"
echo "Next version: $NEW_TAG"

# Generate Release Notes
generate_release_notes() {
  PREV_TAG=$LATEST_TAG
  REPO=$GITHUB_REPOSITORY

  # Initialize sections
  declare -A SECTIONS=(
    ["BREAKING_CHANGES"]=""
    ["FEATURES"]=""
    ["FIXES"]=""
    ["DOCS"]=""
    ["OTHER"]=""
    ["MERGES"]=""
  )

  echo "Processing commits between $PREV_TAG and HEAD..."

  # Store all commits in an array
  readarray -t COMMITS < <(git log --reverse $PREV_TAG..HEAD --pretty=format:"%H|%s|%an")

  # Process each commit
  for line in "${COMMITS[@]}"; do
    COMMIT_HASH=$(echo "$line" | cut -d'|' -f1)
    COMMIT_MSG=$(echo "$line" | cut -d'|' -f2)
    COMMIT_AUTHOR=$(echo "$line" | cut -d'|' -f3)
    PR_NUMBER=$(echo "$COMMIT_MSG" | grep -oP '#\K[0-9]+' || echo "")

    # Skip merge commits
    if git rev-parse --verify $COMMIT_HASH^2 >/dev/null 2>&1; then
      continue
    fi

    # Create commit link
    COMMIT_LINK="[\`${COMMIT_HASH:0:7}\`](https://github.com/$REPO/commit/$COMMIT_HASH)"
    PR_LINK=""
    [ ! -z "$PR_NUMBER" ] && PR_LINK=" ([#${PR_NUMBER}](https://github.com/$REPO/pull/${PR_NUMBER}))"

    ENTRY="- ${COMMIT_LINK}${PR_LINK}: $COMMIT_MSG ([@$COMMIT_AUTHOR](https://github.com/$COMMIT_AUTHOR))"$'\n'

    if echo "$COMMIT_MSG" | grep -iqE "BREAKING[ -]CHANGE|!:"; then
      SECTIONS["BREAKING_CHANGES"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^feat:"; then
      SECTIONS["FEATURES"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^fix:"; then
      SECTIONS["FIXES"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^docs:"; then
      SECTIONS["DOCS"]+="$ENTRY"
    else
      SECTIONS["OTHER"]+="$ENTRY"
    fi
  done

  # Generate release notes
  {
    echo "## 🎉 Release $NEW_TAG"
    echo

    # Breaking Changes
    if [ ! -z "${SECTIONS["BREAKING_CHANGES"]}" ]; then
      echo "### ⚠️ Breaking Changes"
      echo
      echo "${SECTIONS["BREAKING_CHANGES"]}"
    fi

    # Features
    if [ ! -z "${SECTIONS["FEATURES"]}" ]; then
      echo "### ✨ New Features"
      echo
      echo "${SECTIONS["FEATURES"]}"
    fi

    # Fixes
    if [ ! -z "${SECTIONS["FIXES"]}" ]; then
      echo "### 🐛 Bug Fixes"
      echo
      echo "${SECTIONS["FIXES"]}"
    fi

    # Documentation
    if [ ! -z "${SECTIONS["DOCS"]}" ]; then
      echo "### 📝 Documentation"
      echo
      echo "${SECTIONS["DOCS"]}"
    fi

    # Other Changes
    if [ ! -z "${SECTIONS["OTHER"]}" ]; then
      echo "### 🔹 Other Changes"
      echo
      echo "${SECTIONS["OTHER"]}"
    fi

    echo
    echo "## 📊 Statistics"
    echo
    echo "- Total Commits: \`$(git rev-list --count $PREV_TAG..HEAD)\`"
    echo "- Contributors: \`$(git log $PREV_TAG..HEAD --format="%aN" | sort -u | wc -l)\`"
    echo
    echo "🔗 **[Full Changelog](https://github.com/$REPO/compare/$PREV_TAG...$NEW_TAG)**"
  } > RELEASE_BODY.md
}

# Generate release notes
generate_release_notes

# Create and push new tag
git config --global user.name "github-actions"
git config --global user.email "github-actions@github.com"
git tag -a $NEW_TAG -m "Release $NEW_TAG"
git push origin $NEW_TAG

# Create GitHub Release using GitHub CLI
gh release create $NEW_TAG \
  --title "Release $NEW_TAG" \
  --notes-file RELEASE_BODY.md