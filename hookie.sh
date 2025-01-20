#!/bin/bash

# Function to validate required environment variables
validate_variables() {
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo "Error: GITHUB_TOKEN is not set. Please set it before in your enviorment variables."
        exit 1
    fi

    if [[ -z "$NOTIFICATION_WEBHOOK" ]]; then
        echo "Error: NOTIFICATION_WEBHOOK is not set. Please set it before in your enviorment variables."
        exit 1
    fi

    if [[ -z "$NOTIFIED_WEBHOOKS_FILE" ]]; then
        echo "Error: NOTIFIED_WEBHOOKS_FILE is not set. Please set it before in your enviorment variables."
        exit 1
    fi
}

# Validate environment variables
validate_variables


# Main loop
while true; do

# Initialize the notified webhooks file
if [ ! -f "$NOTIFIED_WEBHOOKS_FILE" ]; then
    touch "$NOTIFIED_WEBHOOKS_FILE"
fi

# Temporary in-memory list for this run
declare -A notified_in_run

# Function to normalize webhook URLs
normalize_webhook_url() {
    local url="$1"
    echo "$url" | sed -E 's/[+[:space:]]+$//'
}

# Function to send a Discord notification
send_discord_notification() {
    local found_webhook="$1"
    local repo="$2"
    local commit_sha="$3"

    echo "Sending Discord notification for detected webhook..."
    curl -s -X POST -H "Content-Type: application/json" \
        -d "$(generate_discord_payload "$found_webhook" "$repo" "$commit_sha")" \
        "$NOTIFICATION_WEBHOOK"
}

# Function to generate the Discord message payload
generate_discord_payload() {
    local found_webhook="$1"
    local repo="$2"
    local commit_sha="$3"

    local sanitized_webhook=$(echo "$found_webhook" | sed 's/"/\\"/g')

    cat <<EOF
{
  "content": "⚠️ A Discord webhook was detected in a commit!",
  "embeds": [
    {
      "title": "Webhook Detected",
      "description": "A potential Discord webhook was found in the repository **$repo**.",
      "fields": [
        {
          "name": "Webhook URL",
          "value": "$sanitized_webhook"
        },
        {
          "name": "Commit SHA",
          "value": "$commit_sha"
        }
      ],
      "color": 15158332
    }
  ]
}
EOF
}

# Function to check if a webhook has already been notified
is_webhook_notified() {
    local webhook="$1"
    local normalized_webhook=$(normalize_webhook_url "$webhook")
    grep -Fxq "$normalized_webhook" "$NOTIFIED_WEBHOOKS_FILE" || [[ -n "${notified_in_run[$normalized_webhook]}" ]]
}

# Function to mark a webhook as notified
mark_webhook_notified() {
    local webhook="$1"
    local normalized_webhook=$(normalize_webhook_url "$webhook")
    echo "$normalized_webhook" >> "$NOTIFIED_WEBHOOKS_FILE"
    notified_in_run["$normalized_webhook"]=1
}

# Define the Discord webhook regex pattern
DISCORD_WEBHOOK_PATTERN="https://discord\.com/api/webhooks/"

# Function to search commits in a repository for webhooks
search_commits_for_webhooks() {
    local repo="$1"

    echo "Fetching latest commits from $repo..."
    commits=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$repo/commits" | jq -r '.[].sha // empty')

    # Handle empty commits
    if [[ -z "$commits" ]]; then
        echo "No commits found for repository: $repo"
        return
    fi

    echo "Searching commits for Discord webhooks..."
    for commit_sha in $commits; do
        # Fetch the commit data
        commit_files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$repo/commits/$commit_sha")

        # Check for errors in fetching commit data
        if [[ -z "$commit_files" ]]; then
            echo "⚠️ Error: Failed to fetch commit data for $commit_sha. Skipping..."
            continue
        fi

        # Search for webhook patterns in the commit
        if echo "$commit_files" | grep -q "$DISCORD_WEBHOOK_PATTERN"; then
            found_webhook=$(echo "$commit_files" | grep -o "$DISCORD_WEBHOOK_PATTERN[^ \"\']*" | head -n 1)
            normalized_webhook=$(normalize_webhook_url "$found_webhook")
            
            # Check if the webhook has already been notified
            if is_webhook_notified "$normalized_webhook"; then
                echo "✅ Webhook already notified: $normalized_webhook"
            else
                echo "⚠️ Possible Discord webhook found in commit: $commit_sha"
                echo "Webhook: $normalized_webhook"
                send_discord_notification "$normalized_webhook" "$repo" "$commit_sha"
                mark_webhook_notified "$normalized_webhook"
            fi
        else
            echo "✅ No webhooks found in commit: $commit_sha"
        fi
    done
}

# Function to fetch random repositories using GitHub Search API
fetch_random_repositories() {
    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/search/repositories?q=stars:>1&sort=updated&order=desc&per_page=5" | \
        jq -r '.items[].full_name')

    # Filter out any lines that are not valid repository names
    echo "$repos" | grep -E '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$'
}

# Main logic
if [[ "$1" == "--random" ]]; then
    echo "Scanning random repositories..."
    repos=$(fetch_random_repositories)
    if [[ -z "$repos" ]]; then
        echo "No random repositories found."
    fi
    for repo in $repos; do
        echo "Scanning repository: $repo"
        search_commits_for_webhooks "$repo"
    done
elif [[ "$1" == "--user" && -n "$2" ]]; then
    # Scan all repositories of the specified GitHub user
    USER="$2"
    echo "Scanning repositories of user: $USER"
    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/users/$USER/repos?per_page=100" | jq -r '.[].full_name')

    if [[ -z "$repos" ]]; then
        echo "No repositories found for user: $USER"
        exit 1
    fi

    for repo in $repos; do
        echo "Scanning repository: $repo"
        search_commits_for_webhooks "$repo"
    done
elif [[ -n "$1" ]]; then
    echo "Scanning specific repository: $1"
    search_commits_for_webhooks "$1"
else
    echo "Usage: $0 [--random | --user <username> | <owner/repo>]"
    echo "  --random     Scan random repositories."
    echo "  --user <username> Scan all repositories of the specified GitHub user."
    echo "  <owner/repo> Scan a specific repository (e.g., octocat/Hello-World)."
    exit 1
fi

done