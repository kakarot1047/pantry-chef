# Planning

## Goal
A plain Ruby terminal application that tracks pantry ingredients and recipes, shows which recipes can be cooked now, which are almost possible and what is missing, and deducts ingredients only after a successful cook.

## MVP
The nine stories in `docs/user_stories.md` (24 points): pantry management and validation, JSON persistence, recipe management with duplicate protection, a terminal CLI, cookable and almost-makeable matching, and atomic cooking. All nine were attempted; see `docs/backlog.md` for the delivered status of each.

## Stretch features (explicitly out of scope)
Shopping lists, expiration dates, recipe scaling.

## Team and ownership
| Member | Stories | Points |
|--------|---------|-------:|
| Bhaumik Patel | Manage pantry items; Validate pantry input; JSON persistence | 8 |
| Gokulan Valavan | Add and view recipes; Reject duplicate recipes; Terminal CLI | 8 |
| Yashas Suresh | Cookable recipes; Almost-makeable recipes and shortages; Cook a recipe | 8 |

Gokulan is the repository owner and maintained the shared foundation (tooling, docs, issues).

## Technical decisions
- Ruby only; RSpec for tests, SimpleCov for coverage, RuboCop for style. No Rails, no database, no browser UI.
- Business rules live in `lib/` domain classes; the CLI only parses input, calls domain objects, and prints.
- Storage is a single local JSON file written atomically through a temporary file.
- No unit conversion: quantities are comparable only when units match after normalization.
- One shared error class, `PantryChef::ValidationError`, in its own file, plus `PantryChef::StorageError` for I/O failures.

## Branch and PR approach
- `main` is protected; nobody pushes to it directly.
- One branch per owner's track: `feature/<owner>-<topic>`, `chore/...` for shared infrastructure.
- Every change goes through a pull request reviewed by a different teammate. Commits are small and describe one change.
- Each member commits only under their own Git identity.

## Definition of done
A story is done when its acceptance criteria are covered by passing RSpec tests (happy and sad paths), `bundle exec rspec` and `bundle exec rubocop` pass, the PR is merged into `main`, the issue is closed, and its row in `docs/backlog.md` is updated. The issue-closure condition could not be satisfied: story issues were not found in the tracker, so `docs/backlog.md` records PR links instead and states this explicitly rather than implying issues were closed.

## Sequencing as executed
1. Shared foundation (tooling, class skeletons, docs) merged from `chore/projct-foundation`.
2. Bhaumik's Pantry, validation and Storage (PR #2) and Gokulan's Recipe and RecipeBook (PR #5) ran in parallel, since neither depends on the other.
3. Yashas's MatchEngine and cooking (PR #6), which depend on the Pantry and RecipeBook interfaces; built against the teammate branches before those merged.
4. Gokulan's CLI, which depends on all of the above and was therefore last.
5. Final pass: README verified from a fresh clone, backlog, design and retrospective brought in line with what was actually built.

Steps 2 and 3 overlapped by agreeing the interfaces up front in `docs/design.md`, which let the three tracks proceed without waiting on each other. The cost of that approach appears in the retrospective.
