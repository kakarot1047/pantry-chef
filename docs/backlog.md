# Backlog

Status values: `To Do`, `In Progress`, `In Review`, `Done`. Update the row when a PR is opened or merged. Link the GitHub issue once created.

| # | Story | Owner | Points | Status | Issue |
|---|-------|-------|-------:|--------|-------|
| 1 | Manage pantry items | Bhaumik | 3 | In Review | |
| 2 | Validate pantry input | Bhaumik | 2 | In Review | |
| 3 | Save and load pantry and recipes using JSON | Bhaumik | 3 | In Progress | |
| 4 | Add and view recipes | Gokulan | 3 | To Do | |
| 5 | Reject duplicate recipes | Gokulan | 2 | To Do | |
| 6 | Build terminal CLI | Gokulan | 3 | To Do | |
| 7 | Show recipes that can be made | Yashas | 3 | To Do | |
| 8 | Show almost-makeable recipes and shortages | Yashas | 2 | To Do | |
| 9 | Cook a recipe atomically and deduct ingredients | Yashas | 3 | To Do | |

Total: 24 points (Bhaumik 8, Gokulan 8, Yashas 8).

## Bhaumik implementation update - 2026-09-12

- Story 1: normalized add/lookup, additive restocking, absolute updates, removal,
  sorted listing, defensive copies, and pantry serialization implemented and tested.
- Story 2: blank fields, invalid/nonfinite quantities, mismatched units, insufficient
  consumption, and unchanged state after rejected operations implemented and tested.
- Story 3: load/save, missing-file defaults, corruption handling, atomic replacement,
  failure cleanup, and pantry restart workflow implemented and tested. Real RecipeBook
  reconstruction and CLI startup/save integration remain To Do after teammate work lands.
- Stories 1 and 2 are In Review in [draft PR #2](https://github.com/kakarot1047/pantry-chef/pull/2).
  Story 3 remains In Progress pending real RecipeBook/CLI integration. None is marked Done:
  PR review/merge and issue closure have not occurred. Remote main was verified as the
  foundation commit used for this branch. Exact-title issue lookup returned no matches;
  no issue numbers were assumed. See `bhaumik_handoff.md` for evidence.

## Icebox — stretch features (not in this project)
- Shopping list generated from shortages
- Expiration dates on pantry items
- Recipe scaling (cook N servings)
