# Design

This describes the system as built and merged, not as originally proposed.

## Overview
`main.rb` loads saved state through `Storage`, reconstructs the domain objects from it, and
hands them to the CLI. A corrupt or unreadable data file is caught there: the program prints
a readable message and exits non-zero rather than raising through to a stack trace. Domain
classes hold state and rules and perform no terminal I/O.
`Storage` serializes the whole application state to one JSON file.

```
main.rb → Storage#load → { "pantry" => ..., "recipes" => ... }
        → Pantry.from_h / RecipeBook.from_h
        → CLI(pantry:, recipe_book:, match_engine:, storage:, input:, output:)
            ├─ Pantry        what the user has
            ├─ RecipeBook    what the user knows how to make (Recipe objects)
            ├─ MatchEngine   Pantry × RecipeBook → cookable / almost-makeable / cook
            └─ Storage       load and save the whole state as JSON
```

Note that `Storage#load` returns the raw state hash rather than rebuilt objects; converting
it into a `Pantry` and a `RecipeBook` is the caller's job, which in practice means `main.rb`.
This keeps `Storage` independent of the recipe classes.

## Responsibilities

**Pantry** (Bhaumik) — holds items keyed by normalized name
(`"flour" => { "quantity" => 400, "unit" => "g" }`). `add_item` is additive and requires a
matching unit; `update_item` sets an absolute quantity and may relabel the unit without
converting; `remove_item`, `get_item`, `sufficient?` and `consume` round out the API, and
`items` is an alias of `to_h`. Lookups and listings return copies. Validates names, units
and quantities, accepting numeric strings so the CLI never has to parse numbers.

**Recipe** (Gokulan) — immutable value object: `Recipe.new(name:, servings:, ingredients:)`.
Names and units are trimmed and lowercased and the object, its ingredient hash and its
strings are frozen; `to_h` returns independent string copies. Rejects blank names, servings
that are not positive whole numbers, malformed ingredient entries, non-positive or
non-finite quantities, blank units, and the same ingredient listed twice under different
casing.

**RecipeBook** (Gokulan) — `new(recipes = [])`, `add`, `find` (case-insensitive), `all`
(sorted), `size`, `empty?`, `to_h`, `from_h`. Adding a duplicate name raises and leaves the
book unchanged, including through the constructor.

**MatchEngine** (Yashas) — `new(pantry:, recipe_book:)`. `shortages_for(recipe)` returns
`name => { "required", "available", "shortage", "unit" }` for uncovered requirements;
`cookable?`, `cookable_recipes`; `almost_makeable(max_missing: 1)` returns
`[{ "recipe" => Recipe, "shortages" => {...} }]` excluding fully cookable recipes and
raising on a non-positive threshold; `cook(recipe_name)` takes a name, validates every
requirement first, then consumes, returning `{ "recipe" => Recipe, "consumed" => {...} }`.
A unit mismatch counts as fully uncovered. Nothing is deducted unless everything is
available.

**Storage** (Bhaumik) — `save(pantry, recipe_book)` and `load` against a JSON path. Writes
through a temporary file in the destination directory renamed over the target. A missing
file loads as empty state; corrupt data or I/O failure raises `PantryChef::StorageError`.

**CLI** (Gokulan) — menu loop over injected `input`/`output` streams. `run_command(line)`
parses one line, dispatches through a command table, and is the single place that rescues
`ValidationError` and `StorageError`, so no invalid input ends the session. Mutating
commands run through `persist_change`, which snapshots both domain objects, applies the
change, saves, and restores the snapshot in place if the save raises — so a failed write
never leaves memory and disk disagreeing, and a retry cannot apply the same change twice.
Restoring in place rather than rebuilding matters because `MatchEngine` holds references to
the same `Pantry` and `RecipeBook`. It parses command text and formats output; it contains
no business rules.

**CLIFormatting** (Gokulan) — a module included by `CLI`, holding the pure text handling:
parsing an ingredient list from command text (rejecting an ingredient listed twice) and
rendering shortages and consumed amounts for display. No state, no rules, no I/O.

## Command surface
| Group | Commands |
|-------|----------|
| Pantry | `pantry`, `add <name> <qty> <unit>`, `update <name> <qty> [unit]`, `remove <name>` |
| Recipes | `recipes`, `show-recipe <name>`, `add-recipe <name> <servings> "<item qty unit>, ..."` |
| Matching | `can-make`, `almost [n]` |
| Cooking | `cook <name>` |
| Other | `help`, `quit` / `exit`, and end-of-input |

## Shared interface contract
```ruby
Pantry.new(items = {}) / add_item / update_item / remove_item / get_item
Pantry#sufficient?(name, quantity, unit) / consume(name, quantity, unit)
Pantry#to_h (aliased items) / Pantry.from_h(hash)

Recipe.new(name:, servings:, ingredients:) / name / servings / ingredients / to_h
Recipe.from_h(hash)

RecipeBook.new(recipes = []) / add / find / all / size / empty? / to_h
RecipeBook.from_h(hash)

MatchEngine.new(pantry:, recipe_book:)
MatchEngine#shortages_for / cookable? / cookable_recipes
MatchEngine#almost_makeable(max_missing: 1) / cook(recipe_name)

Storage.new(path = Storage::DEFAULT_PATH) / save(pantry, recipe_book) / load

CLI.new(pantry:, recipe_book:, match_engine:, storage:, input: $stdin, output: $stdout)
CLI#run / run_command(line)
```
Ingredient representation everywhere: `{ "flour" => { "quantity" => 400, "unit" => "g" } }`.

## JSON file shape
`RecipeBook#to_h` returns the map keyed by recipe name; `Storage` adds the top-level
`"recipes"` key, so there is exactly one envelope and no nested wrapper:

```json
{
  "pantry":  { "flour": { "quantity": 400, "unit": "g" } },
  "recipes": { "pancakes": { "name": "pancakes", "servings": 4,
                             "ingredients": { "flour": { "quantity": 200, "unit": "g" } } } }
}
```

## Error handling
`PantryChef::ValidationError < ArgumentError` (`lib/validation_error.rb`) is raised by every
domain class for invalid input; `PantryChef::StorageError` covers corrupt files and I/O
failures. The CLI rescues both in `run_command` and prints a message, so sad paths never
terminate the loop.

## Decisions
- No unit conversion; units must match after normalization.
- Save after every mutating command rather than at exit, so a crash does not lose data.
- Names normalized (trimmed, lowercased) at the domain boundary so lookups are consistent.
- Quantity parsing lives in the domain classes, which accept numeric strings, so the CLI
  passes raw tokens through instead of duplicating validation.
- One shared error class in its own file, so no class reopens it with a different parent.
- Mutating commands are all-or-nothing: the CLI rolls its in-memory state back when a save
  fails, so the file on disk is always the authority on what happened.
- Duplicate detection happens twice by design: `CLIFormatting` rejects an ingredient typed
  twice in one command line, and `Recipe` rejects two keys that normalize to the same name.
  The first is about the input text, the second about the data structure.
- `almost_makeable` defaults to one missing ingredient; the CLI's `almost` command passes 2
  to match the documented story default without changing the engine.
