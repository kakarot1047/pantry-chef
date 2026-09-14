# Retrospective

Project 1, 2026-09-11 to 2026-09-14. Team: Gokulan Valavan, Bhaumik Patel, Yashas Suresh.

## What we built
A plain Ruby terminal application, Pantry Chef, covering all nine planned stories: pantry
management with validation, atomic JSON persistence, recipe management with duplicate
protection, cookable and almost-makeable matching with shortages, atomic cooking, and a
terminal menu over all of it. Six classes plus a formatting module, with unit, acceptance,
integration and CLI specs.

## What went well
- **Agreeing interfaces before splitting the work.** `docs/design.md` fixed the class
  signatures and the ingredient representation on day one. That let three people build in
  parallel with no one blocked: Yashas wrote `MatchEngine` against teammate branches before
  they merged and needed no rework when they landed.
- **Keeping business rules out of the CLI.** Because the domain classes did all validation
  and accepted numeric strings, the CLI ended up as parsing, dispatch and printing only.
  That made it testable through injected streams rather than a real terminal, and it meant
  a single rescue point handled every sad path.
- **Reviews caught real defects, not style.** The CLI review found that a failed save left
  memory and disk inconsistent so a retry could double-apply stock, that duplicate
  ingredients in one recipe were silently overwritten, and that a corrupt data file crashed
  startup with a stack trace. All three were genuine bugs that the existing tests did not
  cover, and all three were fixed with tests before merge.
- **The application stayed small on purpose.** Stretch features were cut on day one and
  never crept back in, which is why a late start still finished.

## What did not go well
- **The process artifacts started late.** Work began on 2026-09-11 for a 2026-09-14
  deadline. The code was never the bottleneck; the repository, issues, branching discipline
  and documentation all had to be created under time pressure alongside it.
- **Integration cost more than the coding did.** Three problems surfaced only when branches
  met: two files defined `PantryChef::ValidationError`, which would have broken the moment
  either changed; `RecipeBook#to_h` wrapped its output in a `"recipes"` key that `Storage`
  was already adding; and during one merge, conflict markers were committed and pushed,
  reaching a pull request before anyone noticed.
- **The design document drifted from the code.** It predicted that `Storage#load` would
  return rebuilt objects and that `almost_makeable` would default to two missing
  ingredients; neither was true of the merged implementation. Reading the merged code
  before writing the CLI, rather than trusting the document, avoided a second round of
  rework — but the document should not have been wrong in the first place.
- **Story issues were never created in the tracker**, so the "issue closed" half of our own
  definition of done could not be satisfied. `docs/backlog.md` records pull-request links
  and says so plainly instead.
- **Branch names were typo'd** (`chore/projct-foundation`, `faeture/gokulan-recipes`) and
  kept, because renaming a branch closes its pull request and loses the review thread.

## What we would change next time
- Create the repository, issues and process documents on day one, before any code. They are
  cheap to write early and expensive to reconstruct late.
- Put shared types — the error class above all — in the foundation commit, never in a
  feature branch, so two people cannot independently invent the same class.
- Run the combined suite locally against a teammate's branch before opening a pull request,
  rather than discovering interface mismatches during review.
- Treat a merge as unfinished until `git grep` for conflict markers comes back empty and the
  suite passes; never push straight from a conflicted working tree.
- Update the design document in the same pull request that changes an interface, so it
  describes what exists rather than what was planned.
- Hold at least one pair session on the riskiest integration point. We held none, and the
  three integration defects above are the kind of thing a second pair of eyes catches early.

## Story points completed per member
| Member | Stories | Points |
|--------|---------|-------:|
| Bhaumik Patel | 1 Manage pantry items, 2 Validate pantry input, 3 JSON persistence | 8 |
| Gokulan Valavan | 4 Add and view recipes, 5 Reject duplicates, 6 Terminal CLI | 8 |
| Yashas Suresh | 7 Cookable recipes, 8 Almost-makeable, 9 Cook atomically | 8 |

All 24 points were completed and merged into `main`. Each row corresponds to merged pull
requests: #2, #5, #6 and #10.
