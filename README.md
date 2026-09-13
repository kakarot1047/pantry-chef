# Pantry Chef

A plain Ruby terminal application that tracks the ingredients in your pantry and your recipes, tells you which recipes you can cook right now, which ones you are almost able to cook and what is missing, and deducts ingredients from the pantry only after a successful cook.

## Team
- Gokulan Valavan — recipes, duplicate protection, terminal CLI (repository owner)
- Bhaumik Patel — pantry management, pantry validation, JSON persistence
- Yashas Suresh — cookable and almost-makeable matching, cooking

See `docs/user_stories.md` for all nine stories, owners and points, and `docs/planning.md` for the plan.

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
ruby main.rb
```

The terminal menu is still awaiting Gokulan's implementation, so this command currently
prints a development-status message. The finished classes can be exercised directly:

```bash
ruby -Ilib -rpantry -e "p = PantryChef::Pantry.new; p.add_item('sugar', 200, 'g'); puts p.items"
```

```ruby
require_relative 'lib/recipe_book'

book = PantryChef::RecipeBook.new
book.add(PantryChef::Recipe.new(
  name: 'Pancakes', servings: 4,
  ingredients: { 'flour' => { 'quantity' => 200, 'unit' => 'g' },
                 'eggs'  => { 'quantity' => 2,   'unit' => 'pcs' } }
))
book.find('PANCAKES').servings
# => 4
book.add(PantryChef::Recipe.new(name: 'pancakes', servings: 1,
                                ingredients: { 'flour' => { 'quantity' => 1, 'unit' => 'g' } }))
# => PantryChef::ValidationError: a recipe named 'pancakes' already exists
```

## Tests, coverage and style
```bash
bundle exec rspec        # runs the test suite; coverage report is written to coverage/index.html
bundle exec rubocop      # style check
```

The suite includes unit tests and two domain workflow acceptance scenarios, including
loading saved inventory in a fresh Ruby process. Full terminal acceptance tests await
CLI integration. SimpleCov enforces an 80% minimum; open `coverage/index.html` for its
generated report. Coverage does not imply completion of the remaining class skeletons.

If RuboCop reports **0 files inspected** on Windows, use explicit file paths:

```bash
bundle exec rubocop --cache false Gemfile main.rb lib/cli.rb lib/match_engine.rb lib/pantry.rb lib/recipe.rb lib/recipe_book.rb lib/storage.rb lib/validation_error.rb spec/spec_helper.rb spec/pantry_spec.rb spec/recipe_spec.rb spec/recipe_book_spec.rb spec/storage_spec.rb spec/acceptance/pantry_workflow_spec.rb
```

The foundation currently has style offenses in the empty class skeletons owned by other
stories. See `docs/bhaumik_handoff.md` for exact findings, the passing scope check, and
integration steps.

## Design notes
Business rules live in the `lib/` domain classes, which perform no terminal I/O; the CLI
will only parse input, call domain objects and print. Invalid input raises
`PantryChef::ValidationError` (`lib/validation_error.rb`), which the CLI will be the single
place to rescue; `Storage` raises `PantryChef::StorageError` for corrupt data and I/O
failures. Ingredients are represented everywhere as a hash keyed by normalized name:
`{ "flour" => { "quantity" => 400, "unit" => "g" } }`. `RecipeBook#to_h` returns the map
keyed by recipe name and `Storage` adds the top-level `"recipes"` key, so the saved file is
a single envelope:

```json
{
  "pantry":  { "flour": { "quantity": 500, "unit": "g" } },
  "recipes": { "flatbread": { "name": "flatbread", "servings": 2,
                              "ingredients": { "flour": { "quantity": 200, "unit": "g" } } } }
}
```

No unit conversion is performed. See `docs/design.md`.

## Current status
Pantry management, validation, safe consumption, and atomic JSON storage are implemented
on `feature/bhaumik-pantry-storage` (draft PR #2, not merged). Names and units are trimmed
and lowercased; adding an existing item in the same unit increases its stock. Invalid
operations preserve state. Pantry lookups and sorted listings return copies. Updates set an
absolute positive quantity; an explicit new unit relabels that quantity without converting
it. Consumption requires matching units and removes exhausted items. Storage creates
missing parent directories, returns empty state for a missing save file, and writes through
a temporary file renamed over the target.

Recipe and RecipeBook are implemented on `faeture/gokulan-recipes` (PR #5, not merged):
validated immutable recipes, case-insensitive lookup, duplicate rejection, and
serialization in the shape above. Storage currently preserves recipes as serialized hashes;
wiring `RecipeBook.from_h` into `Storage#load` is an integration step for after both
branches merge.

MatchEngine and CLI remain skeletons. `docs/backlog.md` is the authoritative per-story
status; no story is Done, because no pull request has been merged.

## Limitations
- No unit conversion; quantities are comparable only when units match after normalization.
- Single local JSON file, one writer at a time, no cross-process locking, and no guarantee
  against power loss during a filesystem operation.
- Fractional quantities use Ruby floating-point arithmetic with exact comparisons; no
  rounding tolerance is applied.
- Stretch features (shopping list, expiration dates, recipe scaling) are out of scope.
