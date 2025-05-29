#!/bin/bash

# Project Code
PROJECT_CODE="TTM"

# stash changes
# always go to main branch
# always delete local devel branch
# checkout to base branch
# create new branch
# publish new branch to remote
# pop stash changes

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# STEP 1 (Fetch the latest tag)
# Ensure latest tags are fetched
git fetch --tags --quiet

# Get the latest tag (sorted by version)
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)

# Validation if TAG exits
if [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}No tags found in the repository.${NC}"
    exit 1
fi

# Extract major, minor, and patch versions from the latest tag
if [[ "$LATEST_TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"

    # Increment patch version
    NEXT_TAG="v${MAJOR}.${MINOR}.$((PATCH + 1))"
else
    echo -e "${RED}Latest tag is not in valid semantic version format (vMAJOR.MINOR.PATCH ex:- v0.0.80). Found: ${LATEST_TAG}${NC}"
    exit 1
fi

echo "NEXT TAG -> ${NEXT_TAG}"

# Function to sanitize branch description
sanitize_branch_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# Print welcome message
echo -e "${GREEN}Feature Branch Creation Script${NC}"
echo

# Get base branch selection with main as default
read -p "Enter base branch: (main) " BASE_BRANCH
BASE_BRANCH=${BASE_BRANCH:-main}

if [[ "$BASE_BRANCH" != "main" ]]; then
    echo -e "${RED}Invalid base branch. Only 'main' is supported in this setup.${NC}"
    exit 1
fi

# Get branch name
read -p "Enter branch name (e.g., 'login feature'): " BRANCH_NAME
SANITIZED_BRANCH_NAME=$(sanitize_branch_name "$BRANCH_NAME")

# Stash any uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}Stashing uncommitted changes...${NC}"
    git stash --quiet
    CHANGES_STASHED=true
fi

echo -e "${YELLOW}Syncing branches...${NC}"

# Go to main branch and pull latest changes
git checkout main --quiet
git pull --quiet

# Checkout to base branch
git checkout "$BASE_BRANCH" --quiet

# Create new feature branch
BRANCH_NAME="${PROJECT_CODE}-${SANITIZED_BRANCH_NAME}-${NEXT_TAG}"
echo -e "${GREEN}Creating new feature branch: ${BRANCH_NAME}${NC}"
if ! git checkout -b "$BRANCH_NAME" --quiet; then
    echo -e "${RED}Failed to create new feature branch.${NC}"
    exit 1
fi

# Publish new branch to remote
if ! git push -u origin "$BRANCH_NAME" > /dev/null 2>&1; then
    echo -e "${RED}Failed to publish new branch to remote.${NC}"
    exit 1
fi

# SHA cherry picking part
# Prompt user for commit SHA to cherry-pick
read -p "Enter a commit SHA to cherry-pick into this branch (or leave empty to skip): " COMMIT_SHA

if [ -n "$COMMIT_SHA" ]; then
    echo -e "${YELLOW}Attempting to cherry-pick commit: $COMMIT_SHA${NC}"
    if git cherry-pick "$COMMIT_SHA" --quiet; then
        echo -e "${GREEN}Successfully cherry-picked commit ${COMMIT_SHA}.${NC}"
    else
        echo -e "${RED}Cherry-pick failed. Please resolve conflicts manually.${NC}"
        exit 1
    fi
fi

# Pop stashed changes if any were stashed
if [ "$CHANGES_STASHED" = true ]; then
    echo -e "${YELLOW}Restoring stashed changes...${NC}"
    git stash pop --quiet
fi

# Print success message and next steps
echo
echo -e "${GREEN}Success! Your new branch has been created.${NC}"
echo -e "Base branch: ${YELLOW}${BASE_BRANCH}${NC}"
echo -e "Current branch: ${YELLOW}${BRANCH_NAME}${NC}"
echo
echo "Next steps:"
echo "1. Make your changes"
echo "2. git add ."
echo "3. git commit -m 'your commit message'"
echo "4. git push"
