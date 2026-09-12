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

The terminal menu is still awaiting Gokulan's implementation. Currently this command
prints a development-status message. To try the completed pantry API, run
`ruby -Ilib -rpantry -e "p = PantryChef::Pantry.new; p.add_item('sugar', 200, 'g'); puts p.items"`.

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
bundle exec rubocop --cache false Gemfile main.rb lib/cli.rb lib/match_engine.rb lib/pantry.rb lib/recipe.rb lib/recipe_book.rb lib/storage.rb lib/validation_error.rb spec/spec_helper.rb spec/pantry_spec.rb spec/storage_spec.rb spec/acceptance/pantry_workflow_spec.rb
```

The foundation currently has five style offenses in teammate-owned files. See
`docs/bhaumik_handoff.md` for exact findings, the passing scope check, and integration steps.

## Current status and limitations
Pantry management, validation, safe consumption, and atomic JSON storage are implemented
on `feature/bhaumik-pantry-storage`. Names and units are trimmed and lowercased; adding
an existing item in the same unit increases its stock. Invalid operations preserve state.
Pantry lookups and sorted listings return copies. Updates set an absolute positive quantity;
an explicit new unit relabels that quantity without converting it. Consumption requires
matching units and removes exhausted items.

Storage creates missing parent directories, returns empty state for missing saves, and
raises `PantryChef::StorageError` for corrupt data or I/O errors. Saving writes a temporary
file in the destination directory, flushes and closes it, and renames it over the target.
Recipes are preserved as serialized hashes; actual RecipeBook reconstruction awaits
Gokulan's implementation. Recipe, RecipeBook, MatchEngine, and CLI remain skeletons.
Track progress in `docs/backlog.md`; no PR has been published or merged.

Planned limitations of the finished MVP: no unit conversion (units must match), single local JSON file, no shopping list, expiration dates or recipe scaling.

Additional storage limitations: one writer at a time, no cross-process locking, and no
guarantee against power loss during a filesystem operation. Fractional quantities use
Ruby floating-point arithmetic and exact comparisons; no rounding tolerance is applied.
