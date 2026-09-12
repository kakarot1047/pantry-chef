#!/usr/bin/env bash
# Creates labels and the nine user-story issues from docs/user_stories.md.
# Requires an authenticated GitHub CLI (`gh auth status`). Safe to inspect before running.
# Assignees are added only for known usernames; edit the ASSIGN_* vars when teammates' handles are confirmed.
set -euo pipefail
REPO=kakarot1047/pantry-chef
ASSIGN_GOKULAN=kakarot1047
ASSIGN_BHAUMIK=""   # fill in exact GitHub username when known
ASSIGN_YASHAS=""    # fill in exact GitHub username when known

for spec in "user-story:1d76db" "core:0e8a16" "sad-path:d93f0b" "2-points:fbca04" "3-points:fbca04"; do
  gh label create "${spec%%:*}" --repo "$REPO" --color "${spec##*:}" --force >/dev/null
done

issue() {  # title owner points assignee labels
  local args=(--repo "$REPO" --title "$1" --label "user-story,$5,$3-points"
              --body "**Owner:** $2  **Points:** $3

Acceptance criteria: see the matching section in \`docs/user_stories.md\`.")
  [[ -n "$4" ]] && args+=(--assignee "$4")
  gh issue create "${args[@]}"
}

issue "Manage pantry items"                                Bhaumik 3 "$ASSIGN_BHAUMIK" core
issue "Validate pantry input"                              Bhaumik 2 "$ASSIGN_BHAUMIK" sad-path
issue "Save and load pantry and recipes using JSON"        Bhaumik 3 "$ASSIGN_BHAUMIK" core
issue "Add and view recipes"                               Gokulan 3 "$ASSIGN_GOKULAN" core
issue "Reject duplicate recipes"                           Gokulan 2 "$ASSIGN_GOKULAN" sad-path
issue "Build terminal CLI"                                 Gokulan 3 "$ASSIGN_GOKULAN" core
issue "Show recipes that can be made"                      Yashas  3 "$ASSIGN_YASHAS"  core
issue "Show almost-makeable recipes and shortages"         Yashas  2 "$ASSIGN_YASHAS"  core
issue "Cook a recipe atomically and deduct ingredients"    Yashas  3 "$ASSIGN_YASHAS"  core
