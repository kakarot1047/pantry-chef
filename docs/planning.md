# Planning

## Goal
A plain Ruby terminal application that tracks pantry ingredients and recipes, shows which recipes can be cooked now, which are almost possible and what is missing, and deducts ingredients only after a successful cook.

## MVP
The nine stories in `docs/user_stories.md` (24 points): pantry management and validation, JSON persistence, recipe management with duplicate protection, a terminal CLI, cookable and almost-makeable matching, and atomic cooking.

## Stretch features (explicitly out of scope for now)
Shopping lists, expiration dates, recipe scaling.

## Team and ownership
| Member | Stories | Points |
|--------|---------|-------:|
| Bhaumik Patel | Manage pantry items; Validate pantry input; JSON persistence | 8 |
| Gokulan Valavan | Add and view recipes; Reject duplicate recipes; Terminal CLI | 8 |
| Yashas Suresh | Cookable recipes; Almost-makeable recipes and shortages; Cook a recipe | 8 |

Gokulan is the repository owner and maintains the shared foundation (tooling, docs, issues).

## Technical decisions
- Ruby only; RSpec for tests, SimpleCov for coverage, RuboCop for style. No Rails, no database, no browser UI.
- Business rules live in `lib/` domain classes; the CLI only parses input, calls domain objects, and prints.
- Storage is a single local JSON file.
- No unit conversion: quantities are comparable only when units match after normalization.

## Branch and PR approach
- `main` is protected; nobody pushes to it directly.
- One branch per story or per logical chunk: `feature/<owner>-<topic>` (e.g. `feature/gokulan-recipes`), `chore/...` for shared infrastructure.
- Every change goes through a pull request reviewed by a different teammate. Commits are small and describe one change. PR descriptions link the issue they close.
- Each member commits only under their own Git identity.

## Definition of done
A story is done when its acceptance criteria are covered by passing RSpec tests (happy and sad paths), `bundle exec rspec` and `bundle exec rubocop` pass, the PR is merged into `main`, the issue is closed, and its row in `docs/backlog.md` is updated.

## Sequencing
1. Shared foundation merged (this PR).
2. Bhaumik: Pantry + validation + Storage. Gokulan: Recipe + RecipeBook. These two tracks are independent and run in parallel.
3. Yashas: MatchEngine and cooking, which depend on Pantry and RecipeBook.
4. Gokulan: CLI, which depends on all of the above.
5. Final pass: README verified from a fresh clone, backlog and retrospective completed.
