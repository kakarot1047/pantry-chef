# Retrospective

Project 1, 2026-09-11 to 2026-09-14. The factual observations below are drawn from the
repository history; the judgement sections are for the team to complete together.

## What happened
- The application itself was small and came together quickly once interfaces were agreed:
  six classes, roughly 24 story points, all five core features working end to end.
- Process artifacts were started on 2026-09-11 for a 2026-09-14 deadline, which is late
  relative to the coding itself.
- Agreeing the class interfaces in `docs/design.md` before splitting the work let three
  people build in parallel without blocking on each other. Yashas's MatchEngine was written
  against teammate branches before they merged and needed no rework at integration.
- Integration still cost real time. Three problems surfaced only when branches met:
  two different files defined `PantryChef::ValidationError`; `RecipeBook#to_h` added a
  `"recipes"` wrapper that `Storage` was already adding; and conflict markers were committed
  to a feature branch during a merge and reached a pull request.
- The design document predicted some interfaces incorrectly (`Storage#load` returns the raw
  state hash rather than rebuilt objects; `MatchEngine#almost_makeable` defaults to one
  missing ingredient, not two). Reading the merged code before writing the CLI, rather than
  trusting the document, avoided a second round of rework.
- Branch names were created with typos (`chore/projct-foundation`, `faeture/gokulan-recipes`)
  and kept, because renaming a branch closes its pull request.

## What went well
<!-- Team to complete. -->

## What did not go well
<!-- Team to complete. -->

## What we would change next time
<!-- Team to complete. Candidates from the history above: start the process artifacts on day
     one; put shared types such as the error class in the foundation commit rather than in a
     feature branch; run the combined suite locally before opening a pull request; verify a
     merge is resolved before pushing. -->

## Story points completed per member
| Member | Stories | Points |
|--------|---------|-------:|
| Bhaumik Patel | 1, 2, 3 | 8 |
| Gokulan Valavan | 4, 5, 6 | 8 |
| Yashas Suresh | 7, 8, 9 | 8 |

Confirm each row against the merged pull requests before submitting; do not report points
for work that did not merge.
