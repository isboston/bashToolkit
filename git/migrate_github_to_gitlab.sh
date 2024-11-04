#!/bin/bash

# Parameters to change
GITHUB_USERNAME="old_github_username_or_org"
GITHUB_TOKEN="your_github_token"
GITLAB_TOKEN="your_gitlab_token"
GITLAB_GROUP_ID="your_gitlab_group_id"  # ID of the GitLab group where repositories will be migrated

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "This script requires jq. Install it with 'sudo apt install jq' (or use your system's package manager)."
    exit 1
fi

# Retrieve the list of all repositories from GitHub
repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/users/$GITHUB_USERNAME/repos?per_page=100" | jq -r '.[].name')

# Loop through each repository and migrate it
for repo in $repos; do
    old_url="https://github.com/$GITHUB_USERNAME/$repo.git"
    new_url="https://gitlab.com/$GITLAB_GROUP_ID/$repo.git"

    # Check if the repository already exists on GitLab
    check_repo_response=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/$GITLAB_GROUP_ID%2F$repo")

    if echo "$check_repo_response" | jq -e '.id' > /dev/null; then
        echo "Repository $repo already exists on GitLab. Skipping creation."
    else
        echo "Creating repository $repo on GitLab"

        # Create the repository on GitLab using the API
        create_repo_response=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            --data-urlencode "name=$repo" --data-urlencode "namespace_id=$GITLAB_GROUP_ID" \
            "https://gitlab.com/api/v4/projects")

        # Check for successful repository creation
        if echo "$create_repo_response" | jq -e '.id' > /dev/null; then
            echo "Repository $repo successfully created on GitLab."
        else
            echo "Error creating repository $repo on GitLab: $create_repo_response"
            continue
        fi
    fi

    echo "Migrating $repo from $old_url to $new_url"

    # Clone the old repository in bare mode
    git clone --bare "$old_url" "$repo.git"

    # Navigate into the repository folder
    if cd "$repo.git"; then
        # Add new remote and push all data
        git remote add new-origin "$new_url"
        git push --mirror new-origin

        # Return to the base directory and delete the local clone
        cd ..
        rm -rf "$repo.git"

        echo "Migration of $repo completed."
    else
        echo "Failed to enter directory $repo.git"
    fi
done

echo "All repositories have been migrated."
