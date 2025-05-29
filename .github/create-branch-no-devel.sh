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

# Ensure latest tags are fetched ### <-- ADDED
git fetch --tags --quiet ### <-- ADDED

# Get the latest tag (sorted by version) ### <-- ADDED
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1) ### <-- ADDED

if [ -z "$LATEST_TAG" ]; then ### <-- ADDED
    echo -e "${RED}No tags found in the repository.${NC}" ### <-- ADDED
    exit 1 ### <-- ADDED
fi ### <-- ADDED

# Function to sanitize branch description
sanitize_branch_name() {
    # Convert to lowercase, replace spaces with hyphens, remove special characters
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# Print welcome message
echo -e "${GREEN}Feature Branch Creation Script${NC}"
# echo "This script will create a new feature branch from your selected base branch."
echo

# Get base branch selection with devel as default
read -p "Enter base branch: (devel) " BASE_BRANCH
BASE_BRANCH=${BASE_BRANCH:-devel}

if [[ "$BASE_BRANCH" != "devel" && "$BASE_BRANCH" != "main" ]]; then
    echo -e "${RED}Invalid base branch. Please choose either 'devel' or 'main'.${NC}"
    exit 1
fi


# Get ticket number for the branch with 000 as default
while true; do
    read -p "Enter ticket number: (000) " TICKET_NUM
    TICKET_NUM=${TICKET_NUM:-000}
    if [[ $TICKET_NUM =~ ^[0-9]+$ ]]; then
        break
    else
        echo -e "${RED}Please enter numbers only.${NC}"
    fi
done

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

# Delete local devel branch if it exists
if  git show-ref --verify --quiet refs/heads/devel; then
    git branch -D devel --quiet
fi

# Fetch latest changes from remote devel branch
if ! git branch devel origin/devel > /dev/null 2>&1; then
    echo -e "${RED}Unable to fetch origin/devel.${NC}"
    exit 1
fi

# Checkout to base branch
git checkout "$BASE_BRANCH" --quiet


# Create new feature branch
BRANCH_NAME="${PROJECT_CODE}-${TICKET_NUM}-${SANITIZED_BRANCH_NAME}-${LATEST_TAG}"
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

# Pop stashed changes if any were stashed
if [ "$CHANGES_STASHED" = true ]; then
    echo -e "${YELLOW}Restoring stashed changes...${NC}"
    git stash pop --quiet
fi

# Print success message and next steps
echo
echo -e "${GREEN}Success! Your new feature branch has been created.${NC}"
echo -e "Base branch: ${YELLOW}${BASE_BRANCH}${NC}"
echo -e "Current branch: ${YELLOW}${BRANCH_NAME}${NC}"
echo
echo "Next steps:"
echo "1. Make your changes"
echo "2. git add ."
echo "3. git commit -m 'your commit message'"
echo "4. git push"
