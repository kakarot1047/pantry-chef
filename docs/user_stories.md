# Pantry Chef — User Stories

Nine stories, 24 points, three owners. Points use the Fibonacci scale. Each story is tracked as a GitHub issue of the same title.

| # | Story | Owner | Points |
|---|-------|-------|-------:|
| 1 | Manage pantry items | Bhaumik | 3 |
| 2 | Validate pantry input | Bhaumik | 2 |
| 3 | Save and load pantry and recipes using JSON | Bhaumik | 3 |
| 4 | Add and view recipes | Gokulan | 3 |
| 5 | Reject duplicate recipes | Gokulan | 2 |
| 6 | Build terminal CLI | Gokulan | 3 |
| 7 | Show recipes that can be made | Yashas | 3 |
| 8 | Show almost-makeable recipes and shortages | Yashas | 2 |
| 9 | Cook a recipe atomically and deduct ingredients | Yashas | 3 |

Totals: Bhaumik 8, Gokulan 8, Yashas 8.

---

## 1. Manage pantry items — Bhaumik, 3 points
As a home cook, I want to add, update, and remove pantry items so Pantry Chef knows what I have.

Acceptance criteria:
- An item has a name, a positive numeric quantity, and a nonblank unit.
- Adding an item that already exists (ignoring case) with the same unit increases its quantity.
- An item's quantity can be updated to a new positive value.
- An item can be removed; removing an unknown item produces a useful error, not a crash.
- Items can be listed in a consistent (sorted) order.

## 2. Validate pantry input — Bhaumik, 2 points
As a home cook, I want bad pantry input rejected so my pantry data stays correct.

Acceptance criteria:
- Blank names are rejected.
- Non-numeric, zero, or negative quantities are rejected.
- Blank units are rejected.
- Adding to an existing item with a different unit is rejected (no unit conversion).
- A rejected operation leaves the pantry unchanged and raises a useful error.

## 3. Save and load pantry and recipes using JSON — Bhaumik, 3 points
As a home cook, I want my pantry and recipes saved to a file so they survive between sessions.

Acceptance criteria:
- Pantry and recipe book serialize to one JSON file (`data/pantry_chef.json` by default).
- Loading restores the same pantry and recipes.
- A missing file loads as empty state.
- A corrupt or malformed file produces a useful error (or warning + empty state) instead of a crash.

## 4. Add and view recipes — Gokulan, 3 points
As a home cook, I want to add and view recipes so Pantry Chef knows what meals I can prepare.

Acceptance criteria:
- A recipe has a name, positive serving count, and ingredient requirements.
- Every ingredient requirement has a positive numeric quantity and a nonblank unit.
- An added recipe can be retrieved from the recipe book.
- Recipe names are handled consistently and lookup is case-insensitive.

## 5. Reject duplicate recipes — Gokulan, 2 points
As a home cook, I want duplicate recipe names rejected so my recipe book remains unambiguous.

Acceptance criteria:
- Adding a recipe whose name already exists, ignoring case, is rejected.
- The existing recipe remains unchanged.
- Only one recipe with that name remains.
- The caller receives a useful error.

## 6. Build terminal CLI — Gokulan, 3 points
As a home cook, I want a simple terminal menu so I can use Pantry Chef without writing Ruby code.

Acceptance criteria:
- A readable menu covers pantry, recipes, matching, cooking, and exit.
- Valid selections call the relevant domain objects.
- Invalid selections show a useful message and do not crash the application.
- Core business rules remain outside the CLI.
- Input and output can be injected so CLI behavior can be tested without a real terminal.

## 7. Show recipes that can be made — Yashas, 3 points
As a home cook, I want to see which recipes I can cook right now so I can decide what to make.

Acceptance criteria:
- A recipe is cookable when every required ingredient is present with a matching unit and sufficient quantity.
- Cookable recipes are listed by name.
- An empty pantry or empty recipe book yields an empty result, not an error.

## 8. Show almost-makeable recipes and shortages — Yashas, 2 points
As a home cook, I want to see recipes I am close to making and what I lack so I know what to buy.

Acceptance criteria:
- A recipe missing at most N ingredients (default 2) is listed as almost-makeable.
- Each shortage names the ingredient, the missing quantity, and the unit.
- Fully cookable recipes are not listed as almost-makeable.
- Mismatched units count as a shortage; no unit conversion is attempted.

## 9. Cook a recipe atomically and deduct ingredients — Yashas, 3 points
As a home cook, I want cooking a recipe to deduct the ingredients I used so my pantry stays accurate.

Acceptance criteria:
- Cooking a cookable recipe deducts every required quantity from the pantry.
- Items whose quantity reaches zero are removed.
- If any ingredient is short, nothing is deducted and the shortages are reported (atomic).
- Cooking an unknown recipe produces a useful error.
