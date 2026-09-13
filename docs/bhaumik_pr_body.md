Pantry and Storage were empty foundation classes. This change lets callers manage validated
inventory and save/load pantry and recipe hashes through the agreed domain interfaces.
For example, adding Sugar 200 g then sugar 50 g stores 250 g; invalid quantities and unit
mismatches leave the previous inventory unchanged. Save failures preserve the prior file.

Stories: Manage pantry items (3 points), Validate pantry input (2 points), and Save and load
pantry and recipes using JSON (3 points). Issue links remain to be added after authenticated
lookup; persistence integration remains open.

Changes include normalized lookup, absolute updates, removal, sorted defensive copies,
availability checks, safe consumption, pantry reconstruction, missing-file defaults, and
atomic JSON replacement with temporary-file cleanup. Existing main contracts are preserved:
additive restocking, positional Storage#save, and a hash-based recipes envelope. The empty
Gemfile and Windows test-source discovery were repaired so tests and coverage actually run.

Validation: 65 RSpec examples, 0 failures; SimpleCov 100.0% (119/119 lines). All eight
changed Ruby/tooling files pass RuboCop. The full project retains five foundation offenses
in untouched files: one long main.rb line and four empty teammate-owned classes.
Two domain acceptance scenarios include a fresh-process JSON restart. See README for commands.

Deferred: RecipeBook serialization/reconstruction is tested with a narrow double until its
implementation lands. Full terminal acceptance, CLI persistence wiring, recipes, matching,
and recipe-level cooking remain teammate-owned. Coverage does not establish completion of
those skeletons. Storage assumes a single writer. No pairing or retrospective evidence was created.

Review the Pantry and Storage contracts in docs/bhaumik_handoff.md before integration.
