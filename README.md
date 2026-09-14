# Pantry Chef


Built as part of our Project 1 Submission to CSCE 606-600 course, Fall 2026 at Texas A&M University. 

A plain Ruby terminal application that tracks the ingredients in your pantry and your recipes, tells you which recipes you can cook right now, which ones you are almost able to cook and what is missing, and deducts ingredients from the pantry only after a successful cook.


## Team
- Gokulan Valavan - recipes, duplicate protection, terminal CLI (repository owner)
- Bhaumik Patel - pantry management, pantry validation, JSON persistence
- Yashas Suresh - cookable and almost-makeable matching, cooking

See `docs/user_stories.md` for all nine stories, owners and points, `docs/planning.md` for the plan, and `docs/design.md` for how the classes fit together.

## Setup
Requires Ruby 3.3 or newer for the locked test-tool dependencies and Bundler 4.0.16.
Verified locally with Ruby 4.0.6 on Windows. The application itself uses only Ruby's standard library.

```bash
git clone https://github.com/kakarot1047/pantry-chef.git
cd pantry-chef
gem install bundler -v 4.0.16
bundle install
```

## Run
```bash
ruby main.rb                 # state is saved to data/pantry_chef.json
ruby main.rb other/path.json # or point it at a different state file
```

## Commands
| Group | Commands |
|-------|----------|
| Pantry | `pantry`, `add <name> <qty> <unit>`, `update <name> <qty> [unit]`, `remove <name>` |
| Recipes | `recipes`, `show-recipe <name>`, `add-recipe <name> <servings> "<item qty unit>, ..."` |
| Matching | `can-make`, `almost [n]` |
| Cooking | `cook <name>` |
| Other | `help`, `quit` |

Type `help` at the prompt for the same list. Names are case-insensitive, and every change is
saved immediately, so the next session starts where you left off.

## Example session
```
> add flour 500 g
Stocked flour: 500.0 g
> add-recipe pancakes 4 "flour 200 g, eggs 2 pcs, milk 300 ml"
Added recipe pancakes.
> add-recipe flatbread 2 "flour 200 g"
Added recipe flatbread.
> can-make
  flatbread
> almost
  pancakes - missing eggs (need 2 more pcs), milk (need 300 more ml)
> cook flatbread
Cooked flatbread. Used flour 200 g.
> pantry
  flour: 300.0 g
> cook pancakes
Error: Cannot cook 'pancakes': missing eggs (need 2 more pcs), milk (need 300 more ml)
> quit
Goodbye.
```

Invalid input is reported and the session continues:

```
> add flour lots g
Error: Quantity must be a positive finite number
> dance
Unknown command 'dance'. Type `help` for the menu.
```

## Tests, coverage and style
```bash
bundle exec rspec        # runs the test suite; coverage report is written to coverage/index.html
bundle exec rubocop      # style check
```

The suite covers each class's happy and sad paths, two domain workflow acceptance scenarios
including loading saved inventory in a fresh Ruby process, a cross-class persistence
integration spec built on real objects rather than doubles, and the CLI driven through
injected input and output streams. SimpleCov enforces an 80% minimum; open
`coverage/index.html` for the generated report.

If RuboCop reports **0 files inspected** on Windows, use explicit file paths:

```bash
bundle exec rubocop --cache false Gemfile main.rb lib/*.rb spec/*.rb spec/acceptance/*.rb
```

## Design notes
Business rules live in the `lib/` domain classes, which perform no terminal I/O; the CLI only
parses input, calls domain objects and prints. Invalid input raises
`PantryChef::ValidationError` (`lib/validation_error.rb`) and `Storage` raises
`PantryChef::StorageError` for corrupt data and I/O failures; `CLI#run_command` is the single
place that rescues both. Ingredients are represented everywhere as a hash keyed by normalized
name: `{ "flour" => { "quantity" => 400, "unit" => "g" } }`. `RecipeBook#to_h` returns the map
keyed by recipe name and `Storage` adds the top-level `"recipes"` key, so the saved file is a
single envelope:

```json
{
  "pantry":  { "flour": { "quantity": 500, "unit": "g" } },
  "recipes": { "flatbread": { "name": "flatbread", "servings": 2,
                              "ingredients": { "flour": { "quantity": 200, "unit": "g" } } } }
}
```

`Storage#load` returns that hash rather than rebuilt objects, so `main.rb` is what calls
`Pantry.from_h` and `RecipeBook.from_h`; a corrupt file is reported there and the program
exits rather than raising. Mutating commands are all-or-nothing: if a save fails, the CLI
restores its in-memory state, so the file on disk is always the authority and retrying a
failed command cannot apply it twice. No unit conversion is performed. See `docs/design.md`.

## Status
Complete. All nine stories (24 points) are implemented, reviewed and merged into `main`:
pantry management with validation, JSON persistence, recipe management with duplicate
protection, cookable and almost-makeable matching with shortages, atomic cooking, and the
terminal menu over all of it. `docs/backlog.md` is the authoritative per-story status and
`docs/retrospective.md` records what we would do differently.

## Limitations
- No unit conversion; quantities are comparable only when units match after normalization.
- Pantry quantities entered at the prompt are stored as floating-point numbers, so they
  display as `500.0` rather than `500`; recipe quantities keep whole numbers as integers.
- Single local JSON file, one writer at a time, no cross-process locking, and no guarantee
  against power loss during a filesystem operation.
- Fractional quantities use exact floating-point comparisons; no rounding tolerance.
- Stretch features (shopping list, expiration dates, recipe scaling) are out of scope.
