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
    ["CHORE"]=""
    ["REFACTOR"]=""
    ["TEST"]=""
    ["OTHER"]=""
  )

  echo "Processing commits between $PREV_TAG and HEAD..."

  # Store all commits in an array
  readarray -t COMMITS < <(git log --reverse $PREV_TAG..HEAD --pretty=format:"%H|%s|%ae")

  # Process each commit
  for line in "${COMMITS[@]}"; do
    COMMIT_HASH=$(echo "$line" | cut -d'|' -f1)
    COMMIT_MSG=$(echo "$line" | cut -d'|' -f2)
    COMMIT_EMAIL=$(echo "$line" | cut -d'|' -f3)

    # Extract GitHub username from email (username@users.noreply.github.com)
    COMMIT_AUTHOR=$(echo "$COMMIT_EMAIL" | sed -n 's/\(.*\)@users.noreply.github.com/\1/p')
    # If not a GitHub noreply email, use the local part of the email
    if [ -z "$COMMIT_AUTHOR" ]; then
      COMMIT_AUTHOR=$(echo "$COMMIT_EMAIL" | cut -d@ -f1)
    fi

    # Extract PR, issue numbers from commit message
    PR_NUMBERS=$(echo "$COMMIT_MSG" | grep -oP '(?<=[Cc]loses? |[Ff]ixes? |#)\K[0-9]+' || echo "")
    ISSUE_NUMBERS=$(echo "$COMMIT_MSG" | grep -oP '(?<=[Rr]esolves? |[Ff]ixes? |[Cc]loses? |[Rr]elates? to )[Ii]ssue #\K[0-9]+' || echo "")

    # Skip merge commits
    if git rev-parse --verify $COMMIT_HASH^2 >/dev/null 2>&1; then
      continue
    fi

    # Create commit link
    COMMIT_LINK="[\`${COMMIT_HASH:0:7}\`](https://github.com/$REPO/commit/$COMMIT_HASH)"

    # Create PR and Issue links
    PR_LINKS=""
    for PR in $PR_NUMBERS; do
      PR_LINKS+=" ([#${PR}](https://github.com/$REPO/pull/${PR}))"
    done

    ISSUE_LINKS=""
    for ISSUE in $ISSUE_NUMBERS; do
      ISSUE_LINKS+=" ([Issue #${ISSUE}](https://github.com/$REPO/issues/${ISSUE}))"
    done

    # Clean commit message - remove PR numbers and standardize
    CLEAN_MSG=$(echo "$COMMIT_MSG" | sed -E 's/(#[0-9]+|fixes #[0-9]+|closes #[0-9]+|resolves #[0-9]+)//gi' | sed 's/  / /g' | sed 's/^ //g' | sed 's/ $//g')

    ENTRY="- ${COMMIT_LINK}${PR_LINKS}${ISSUE_LINKS}: ${CLEAN_MSG} ([@${COMMIT_AUTHOR}](https://github.com/${COMMIT_AUTHOR}))"$'\n'

    if echo "$COMMIT_MSG" | grep -iqE "BREAKING[ -]CHANGE|!:"; then
      SECTIONS["BREAKING_CHANGES"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^feat:"; then
      SECTIONS["FEATURES"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^fix:"; then
      SECTIONS["FIXES"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^docs:"; then
      SECTIONS["DOCS"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^chore:"; then
      SECTIONS["CHORE"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^refactor:"; then
      SECTIONS["REFACTOR"]+="$ENTRY"
    elif echo "$COMMIT_MSG" | grep -iq "^test:"; then
      SECTIONS["TEST"]+="$ENTRY"
    else
      SECTIONS["OTHER"]+="$ENTRY"
    fi
  done

  # Generate release notes
  {
    echo "## 🎉 Release $NEW_TAG"
    echo
    echo "## What's Changed 🔄"
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
      echo "### 📝 Documentation Updates"
      echo
      echo "${SECTIONS["DOCS"]}"
    fi

    # Chore
    if [ ! -z "${SECTIONS["CHORE"]}" ]; then
      echo "### 🔧 Maintenance"
      echo
      echo "${SECTIONS["CHORE"]}"
    fi

    # Refactor
    if [ ! -z "${SECTIONS["REFACTOR"]}" ]; then
      echo "### ♻️ Code Refactoring"
      echo
      echo "${SECTIONS["REFACTOR"]}"
    fi

    # Tests
    if [ ! -z "${SECTIONS["TEST"]}" ]; then
      echo "### ✅ Tests"
      echo
      echo "${SECTIONS["TEST"]}"
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
    echo "- Contributors: \`$(git log $PREV_TAG..HEAD --format="%aE" | sort -u | wc -l)\`"
    echo "- Lines Changed: \`+$(git diff --shortstat $PREV_TAG..HEAD | grep -oP '\d+ insertion' | cut -d' ' -f1 || echo "0")\` \`-$(git diff --shortstat $PREV_TAG..HEAD | grep -oP '\d+ deletion' | cut -d' ' -f1 || echo "0")\`"
    echo
    echo "## 🔗 Links"
    echo
    echo "- [Full Changelog](https://github.com/$REPO/compare/$PREV_TAG...$NEW_TAG)"
    echo "- [Release Notes](https://github.com/$REPO/releases/tag/$NEW_TAG)"

    echo
    echo "---"
    echo
    echo "*This release note was automatically generated by [auto-release-action](https://github.com/$REPO)*"
  } > RELEASE_BODY.md
}

# Generate release notes
generate_release_notes

# Create and push new tag
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git tag -a $NEW_TAG -m "Release $NEW_TAG"
git push origin $NEW_TAG

# Create GitHub Release
gh release create $NEW_TAG \
  --title "Release $NEW_TAG" \
  --notes-file RELEASE_BODY.md