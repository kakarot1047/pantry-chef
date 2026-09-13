# Backlog

Status values: `To Do`, `In Progress`, `In Review`, `Done`. Update the row when a PR is opened or merged. Link the GitHub issue once created.

| # | Story | Owner | Points | Status | Issue |
|---|-------|-------|-------:|--------|-------|
| 1 | Manage pantry items | Bhaumik | 3 | In Review | |
| 2 | Validate pantry input | Bhaumik | 2 | In Review | |
| 3 | Save and load pantry and recipes using JSON | Bhaumik | 3 | In Progress | |
| 4 | Add and view recipes | Gokulan | 3 | In Review | |
| 5 | Reject duplicate recipes | Gokulan | 2 | In Review | |
| 6 | Build terminal CLI | Gokulan | 3 | To Do | |
| 7 | Show recipes that can be made | Yashas | 3 | In Progress | |
| 8 | Show almost-makeable recipes and shortages | Yashas | 2 | In Progress | |
| 9 | Cook a recipe atomically and deduct ingredients | Yashas | 3 | In Progress | |

Total: 24 points (Bhaumik 8, Gokulan 8, Yashas 8).

Issue links are blank because issue numbers have not been confirmed against the tracker.
Fill each cell in once the matching issue is verified; no number has been assumed.
No story is marked `Done`: no pull request has been reviewed, merged, or closed an issue.

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

## Gokulan implementation update - 2026-09-13

- Story 4: `Recipe` validates name, servings, ingredient names, positive finite
  quantities, and units, normalizes them, freezes the object and its strings, and
  serializes through `to_h`/`Recipe.from_h`. `RecipeBook` adds, looks up
  case-insensitively, lists sorted, and serializes as a map keyed by recipe name.
- Story 5: duplicate names are rejected ignoring case, from both `add` and the
  constructor; the existing recipe is left unchanged and exactly one remains.
- Both are In Review in [PR #5](https://github.com/kakarot1047/pantry-chef/pull/5),
  which is not merged. Neither is Done.
- Story 6 (terminal CLI) remains To Do and is blocked on Yashas's matching and
  cooking work in addition to the pantry and storage work above.

## Yashas implementation update - 2026-09-13

- Story 7: `MatchEngine#shortages_for`, `#cookable?`, and `#cookable_recipes` compare
  every requirement against pantry quantity and unit without mutating inventory.
- Story 8: `#almost_makeable(max_missing:)` returns structured shortages for recipes
  with 1..max_missing short ingredient names; cookable recipes are excluded;
  non-positive thresholds raise `ValidationError`.
- Story 9: `#cook(recipe_name)` finds case-insensitively, validates all shortages
  first, then consumes through `Pantry#consume`; failures leave pantry unchanged.
- Stories 7–9 are In Progress on `feature/yashas-matching-cooking`. Not Done:
  PR review/merge and issue closure have not occurred. Issue links left blank
  because numbers were not confirmed. Built against Pantry/Recipe/RecipeBook
  interfaces from teammate branches (not yet merged to `main`).

## Icebox — stretch features (not in this project)
- Shopping list generated from shortages
- Expiration dates on pantry items
- Recipe scaling (cook N servings)
