# Backlog

Status values: `To Do`, `In Progress`, `In Review`, `Done`. Update the row when a PR is opened or merged.

| # | Story | Owner | Points | Status | PR |
|---|-------|-------|-------:|--------|----|
| 1 | Manage pantry items | Bhaumik | 3 | Done | [#2](https://github.com/kakarot1047/pantry-chef/pull/2) |
| 2 | Validate pantry input | Bhaumik | 2 | Done | [#2](https://github.com/kakarot1047/pantry-chef/pull/2) |
| 3 | Save and load pantry and recipes using JSON | Bhaumik | 3 | Done | [#2](https://github.com/kakarot1047/pantry-chef/pull/2) |
| 4 | Add and view recipes | Gokulan | 3 | Done | [#5](https://github.com/kakarot1047/pantry-chef/pull/5) |
| 5 | Reject duplicate recipes | Gokulan | 2 | Done | [#5](https://github.com/kakarot1047/pantry-chef/pull/5) |
| 6 | Build terminal CLI | Gokulan | 3 | In Review | |
| 7 | Show recipes that can be made | Yashas | 3 | Done | [#6](https://github.com/kakarot1047/pantry-chef/pull/6) |
| 8 | Show almost-makeable recipes and shortages | Yashas | 2 | Done | [#6](https://github.com/kakarot1047/pantry-chef/pull/6) |
| 9 | Cook a recipe atomically and deduct ingredients | Yashas | 3 | Done | [#6](https://github.com/kakarot1047/pantry-chef/pull/6) |

Total: 24 points (Bhaumik 8, Gokulan 8, Yashas 8). Completed and merged: 21 points.
Story 6 moves to `Done` once its pull request is reviewed and merged.

Caveat on the definition of done: `docs/planning.md` also requires the matching issue to be
closed. Story issues were not found in the tracker by any teammate, so no issue numbers were
assumed and no issue links are recorded. Every other condition — acceptance criteria covered
by passing specs, `rspec` and `rubocop` green, PR merged into `main` — is met for the eight
stories marked Done.

## Bhaumik implementation update - 2026-09-12

- Story 1: normalized add/lookup, additive restocking, absolute updates, removal,
  sorted listing, defensive copies, and pantry serialization implemented and tested.
- Story 2: blank fields, invalid/nonfinite quantities, mismatched units, insufficient
  consumption, and unchanged state after rejected operations implemented and tested.
- Story 3: load/save, missing-file defaults, corruption handling, atomic replacement,
  failure cleanup, and pantry restart workflow implemented and tested.
- Merged into `main` on 2026-09-14 via PR #2.

## Gokulan implementation update - 2026-09-13

- Story 4: `Recipe` validates name, servings, ingredient names, positive finite
  quantities, and units, normalizes them, freezes the object and its strings, and
  serializes through `to_h`/`Recipe.from_h`. `RecipeBook` adds, looks up
  case-insensitively, lists sorted, and serializes as a map keyed by recipe name.
- Story 5: duplicate names are rejected ignoring case, from both `add` and the
  constructor; the existing recipe is left unchanged and exactly one remains.
- Review feedback addressed before merge: `ValidationError` re-parented to `ArgumentError`,
  the duplicate `lib/errors.rb` dropped in favour of `lib/validation_error.rb`, the
  redundant `"recipes"` wrapper removed from `RecipeBook#to_h`, non-finite quantities
  rejected, and recipe strings frozen with `to_h` returning independent copies.
- Merged into `main` on 2026-09-14 via PR #5.

## Yashas implementation update - 2026-09-13

- Story 7: `MatchEngine#shortages_for`, `#cookable?`, and `#cookable_recipes` compare
  every requirement against pantry quantity and unit without mutating inventory.
- Story 8: `#almost_makeable(max_missing:)` returns structured shortages for recipes
  with 1..max_missing short ingredient names; cookable recipes are excluded;
  non-positive thresholds raise `ValidationError`.
- Story 9: `#cook(recipe_name)` finds case-insensitively, validates all shortages
  first, then consumes through `Pantry#consume`; failures leave the pantry unchanged.
- Merged into `main` on 2026-09-14 via PR #6.

## Gokulan implementation update - 2026-09-14

- Story 6: `CLI` runs a menu loop over injected `input`/`output` streams, dispatches
  through a command table, and rescues `ValidationError` and `StorageError` in one place
  so no invalid input ends the session. `main.rb` loads state through `Storage`,
  reconstructs `Pantry` and `RecipeBook` from it, and wires both into `MatchEngine`.
  Mutating commands persist immediately. No business rules live in the CLI.
- `MatchEngine#almost_makeable` defaults to `max_missing: 1`; the `almost` command passes
  `2` explicitly so the documented story-8 default holds without changing his class.

## Icebox — stretch features (not in this project)
- Shopping list generated from shortages
- Expiration dates on pantry items
- Recipe scaling (cook N servings)
