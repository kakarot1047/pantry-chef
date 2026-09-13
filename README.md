# Pantry Chef

A plain Ruby terminal application that tracks the ingredients in your pantry and your recipes, tells you which recipes you can cook right now, which ones you are almost able to cook and what is missing, and deducts ingredients from the pantry only after a successful cook.

## Team
- Gokulan Valavan — recipes, duplicate protection, terminal CLI (repository owner)
- Bhaumik Patel — pantry management, pantry validation, JSON persistence
- Yashas Suresh — cookable and almost-makeable matching, cooking

See `docs/user_stories.md` for all nine stories, owners and points, and `docs/planning.md` for the plan.

## Setup
Requires Ruby 3.1 or newer.

```bash
git clone https://github.com/kakarot1047/pantry-chef.git
cd pantry-chef
bundle install
```

## Run
```bash
ruby main.rb
```
The terminal interface is not implemented yet; `main.rb` currently prints a status message.

## Tests, coverage and style
```bash
bundle exec rspec        # runs the test suite; coverage report is written to coverage/index.html
bundle exec rubocop      # style check
```

## Current status
| Area | Owner | Status |
|------|-------|--------|
| Recipe and RecipeBook (add/view recipes, duplicate rejection) | Gokulan | Implemented, tested |
| Pantry management and validation | Bhaumik | In progress |
| JSON persistence | Bhaumik | In progress |
| MatchEngine (cookable, almost-makeable, cook) | Yashas | In progress |
| Terminal CLI | Gokulan | Not started (depends on the above) |

`docs/backlog.md` is the authoritative per-story status.

### Using the recipe classes today
Until the CLI exists, the recipe classes can be exercised from `irb`:

```ruby
require_relative 'lib/recipe_book'

book = PantryChef::RecipeBook.new
book.add(PantryChef::Recipe.new(
  name: 'Pancakes', servings: 4,
  ingredients: { 'flour' => { 'quantity' => 200, 'unit' => 'g' },
                 'eggs'  => { 'quantity' => 2,   'unit' => 'pcs' } }
))
book.find('PANCAKES').servings   # => 4
book.add(PantryChef::Recipe.new(name: 'pancakes', servings: 1, ingredients: { 'flour' => { 'quantity' => 1, 'unit' => 'g' } }))
# => PantryChef::ValidationError: a recipe named 'pancakes' already exists
```

## Design notes
Business rules live in the `lib/` domain classes, which do no terminal I/O; the CLI will only parse input, call domain objects and print. Invalid input raises `PantryChef::ValidationError` (`lib/errors.rb`), which the CLI will be the single place to rescue. Ingredients are represented everywhere as a hash keyed by normalized name: `{ "flour" => { "quantity" => 400, "unit" => "g" } }`. No unit conversion is performed. See `docs/design.md`.

## Limitations
- No unit conversion (units must match after normalization).
- Single local JSON file for persistence.
- Stretch features (shopping list, expiration dates, recipe scaling) are out of scope for this project.