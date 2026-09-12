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

## Tests, coverage and style
```bash
bundle exec rspec        # runs the test suite; coverage report is written to coverage/index.html
bundle exec rubocop      # style check
```

## Current status and limitations
The project is at the foundation stage: tooling, documentation, and empty class skeletons are in place. No user-story behavior is implemented yet, `main.rb` only prints a status message, and the test suite is empty. Track progress in `docs/backlog.md`.

Planned limitations of the finished MVP: no unit conversion (units must match), single local JSON file, no shopping list, expiration dates or recipe scaling.
