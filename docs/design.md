# Design

## Overview
`main.rb` constructs the domain objects and hands them to the CLI. Domain classes hold state and rules and perform no terminal I/O. `Storage` serializes the whole application state to one JSON file.

```
main.rb → CLI(pantry:, recipe_book:, match_engine:, storage:, input:, output:)
            ├─ Pantry        what the user has
            ├─ RecipeBook    what the user can make (Recipe objects)
            ├─ MatchEngine   Pantry × RecipeBook → cookable / almost / shortages / cook
            └─ Storage       load and save Pantry + RecipeBook as JSON
```

## Responsibilities

**Pantry** (Bhaumik) — holds pantry items keyed by normalized name (`"flour" => { "quantity" => 400, "unit" => "g" }`). Adds, updates, removes, lists. Validates names, quantities and units and refuses unit mismatches. Provides quantity/unit lookup so MatchEngine can compare requirements. Serializes with `to_h` / `from_h`.

**Recipe** (Gokulan) — value object: `Recipe.new(name:, servings:, ingredients:)`. `ingredients` is a hash keyed by normalized ingredient name with `"quantity"` and `"unit"`. Validates blank name, non-positive servings, malformed ingredients, non-positive quantities, blank units. `to_h` / `Recipe.from_h`.

**RecipeBook** (Gokulan) — `RecipeBook.new(recipes = [])`, `add(recipe)`, `find(name)`, `all`, `to_h`, `RecipeBook.from_h`. Lookup is case-insensitive; adding a duplicate name raises and leaves the book unchanged.

**MatchEngine** (Yashas) — constructed with a Pantry and a RecipeBook. Reports cookable recipes, almost-makeable recipes with their shortages (ingredient, missing quantity, unit), and performs an atomic cook: verify every requirement first, deduct only if all are satisfied.

**Storage** (Bhaumik) — `save(pantry, recipe_book)` and `load` against a JSON path. Missing file → empty state; malformed file → useful error or warning.

**CLI** (Gokulan) — menu loop over injected `input`/`output` streams. Parses a selection, calls the relevant domain method, prints the result, persists after mutating actions, and handles invalid input and EOF without crashing. Contains no business rules.

## Shared interface contract
```ruby
Recipe.new(name:, servings:, ingredients:)
recipe.name / recipe.servings / recipe.ingredients / recipe.to_h
Recipe.from_h(hash)

RecipeBook.new(recipes = [])
recipe_book.add(recipe) / find(name) / all / to_h
RecipeBook.from_h(hash)

CLI.new(pantry:, recipe_book:, match_engine:, storage:, input: $stdin, output: $stdout)
```
Ingredient representation everywhere: `{ "flour" => { "quantity" => 400, "unit" => "g" } }`.

## JSON file shape
```json
{
  "pantry":  { "flour": { "quantity": 400, "unit": "g" } },
  "recipes": { "pancakes": { "name": "pancakes", "servings": 4,
                             "ingredients": { "flour": { "quantity": 200, "unit": "g" } } } }
}
```

## Error handling
Domain classes raise a project-specific error (e.g. `PantryChef::ValidationError`) for invalid input. The CLI is the single place that rescues it and prints a message, so sad paths never terminate the loop.

## Decisions
- No unit conversion (out of scope; units must match after normalization).
- Save after every mutating action rather than at exit, so a crash does not lose data.
- Names normalized (trimmed, lowercased) at the domain boundary so lookups are consistent.
