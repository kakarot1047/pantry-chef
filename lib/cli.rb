# frozen_string_literal: true

require_relative 'validation_error'
require_relative 'storage'
require_relative 'recipe'
require_relative 'cli_formatting'

module PantryChef
  # The terminal menu. It reads a command, hands it to the right object, and prints the result.
  # It has no business rules of its own.
  # Owner: Gokulan (Build terminal CLI).
  class CLI
    include CLIFormatting

    # Each command word and the method that handles it.
    COMMANDS = {
      'help' => :show_help,
      'pantry' => :show_pantry,
      'add' => :add_item,
      'update' => :update_item,
      'remove' => :remove_item,
      'recipes' => :list_recipes,
      'show-recipe' => :show_recipe,
      'add-recipe' => :add_recipe,
      'can-make' => :show_cookable,
      'almost' => :show_almost,
      'cook' => :cook
    }.freeze

    # Words that end the session.
    EXIT_COMMANDS = %w[quit exit].freeze
    # "almost" shows recipes missing up to this many ingredients unless you give a number.
    DEFAULT_MAX_MISSING = 2

    # What help prints. Same grouping as the README.
    MENU = <<~MENU
      Pantry:   pantry | add <name> <qty> <unit> | update <name> <qty> [unit] | remove <name>
      Recipes:  recipes | show-recipe <name> | add-recipe <name> <servings> "<item qty unit>, ..."
      Matching: can-make | almost [n]
      Cooking:  cook <name>
      Other:    help | quit
    MENU

    # Input and output are passed in so tests can use strings instead of a real terminal.
    def initialize(pantry:, recipe_book:, match_engine:, storage:, input: $stdin, output: $stdout)
      @pantry = pantry
      @recipe_book = recipe_book
      @match_engine = match_engine
      @storage = storage
      @input = input
      @output = output
    end

    # Keeps reading commands until the user quits or the input runs out.
    def run
      @output.puts 'Pantry Chef. Type `help` for the menu.'
      loop do
        @output.print '> '
        line = @input.gets
        break if line.nil? || run_command(line) == :quit
      end
      @output.puts 'Goodbye.'
    end

    # Runs one line. Returns :quit when the user wants to leave.
    # Any error from the domain is printed here, so one bad command never ends the session.
    def run_command(line)
      command, rest = split_command(line)
      return if command.nil?
      return :quit if EXIT_COMMANDS.include?(command)

      handler = COMMANDS[command]
      return unknown(command) if handler.nil?

      send(handler, rest)
    rescue ValidationError, StorageError => e
      @output.puts "Error: #{e.message}"
    end

    private

    # Splits "add flour 500 g" into the command and the rest of the line.
    def split_command(line)
      command, rest = line.to_s.strip.split(/\s+/, 2)
      return [nil, nil] if command.nil? || command.empty?

      [command.downcase, rest.to_s.strip]
    end

    # Friendly message for a command we do not recognise.
    def unknown(command)
      @output.puts "Unknown command '#{command}'. Type `help` for the menu."
    end

    def show_help(_rest)
      @output.puts MENU
    end

    # pantry: lists everything we have.
    def show_pantry(_rest)
      items = @pantry.items
      return @output.puts('Pantry is empty.') if items.empty?

      items.each { |name, item| @output.puts "  #{name}: #{item['quantity']} #{item['unit']}" }
    end

    # add <name> <qty> <unit>
    def add_item(rest)
      name, quantity, unit = rest.split(/\s+/, 3)
      raise ValidationError, 'Usage: add <name> <qty> <unit>' if unit.nil?

      item = persist_change { @pantry.add_item(name, quantity, unit) }
      @output.puts "Stocked #{name}: #{item['quantity']} #{item['unit']}"
    end

    # update <name> <qty> [unit]
    def update_item(rest)
      name, quantity, unit = rest.split(/\s+/, 3)
      raise ValidationError, 'Usage: update <name> <qty> [unit]' if quantity.nil?

      item = persist_change { @pantry.update_item(name, quantity, unit) }
      @output.puts "Updated #{name}: #{item['quantity']} #{item['unit']}"
    end

    # remove <name>
    def remove_item(rest)
      raise ValidationError, 'Usage: remove <name>' if rest.empty?

      item = persist_change { @pantry.remove_item(rest) }
      @output.puts "Removed #{rest} (was #{item['quantity']} #{item['unit']})"
    end

    # recipes: lists every recipe and how many it serves.
    def list_recipes(_rest)
      recipes = @recipe_book.all
      return @output.puts('No recipes yet.') if recipes.empty?

      recipes.each { |recipe| @output.puts "  #{recipe.name} (serves #{recipe.servings})" }
    end

    # show-recipe <name>: one recipe and what it needs.
    def show_recipe(rest)
      raise ValidationError, 'Usage: show-recipe <name>' if rest.empty?

      recipe = @recipe_book.find(rest)
      return @output.puts("Recipe not found: #{rest}") if recipe.nil?

      @output.puts "#{recipe.name} (serves #{recipe.servings})"
      recipe.ingredients.each { |name, need| @output.puts "  #{name}: #{need['quantity']} #{need['unit']}" }
    end

    # add-recipe <name> <servings> "<item qty unit>, ..."
    def add_recipe(rest)
      name, servings, spec = rest.split(/\s+/, 3)
      raise ValidationError, 'Usage: add-recipe <name> <servings> "<item qty unit>, ..."' if spec.nil?

      recipe = Recipe.new(name: name, servings: servings, ingredients: parse_ingredients(spec))
      persist_change { @recipe_book.add(recipe) }
      @output.puts "Added recipe #{recipe.name}."
    end

    # can-make: recipes we have everything for.
    def show_cookable(_rest)
      recipes = @match_engine.cookable_recipes
      return @output.puts('Nothing can be made right now.') if recipes.empty?

      recipes.each { |recipe| @output.puts "  #{recipe.name}" }
    end

    # almost [n]: recipes we are close to, and what they still need.
    def show_almost(rest)
      max_missing = rest.empty? ? DEFAULT_MAX_MISSING : Integer(rest, exception: false)
      matches = @match_engine.almost_makeable(max_missing: max_missing)
      return @output.puts('Nothing is close.') if matches.empty?

      matches.each do |match|
        @output.puts "  #{match['recipe'].name} - missing #{format_shortages(match['shortages'])}"
      end
    end

    # cook <name>: the engine does the checking, we save and report back.
    def cook(rest)
      raise ValidationError, 'Usage: cook <name>' if rest.empty?

      result = persist_change { @match_engine.cook(rest) }
      @output.puts "Cooked #{result['recipe'].name}. Used #{format_consumed(result['consumed'])}."
    end

    # Applies a change and saves it. If the save fails the in-memory state is put
    # back, so memory and disk never disagree and a retry cannot double-apply.
    def persist_change
      snapshot = [@pantry.to_h, @recipe_book.to_h]
      result = yield
      @storage.save(@pantry, @recipe_book)
      result
    rescue StorageError
      restore(*snapshot)
      raise
    end

    # Puts the pantry and recipe book back to the snapshot. It changes the same objects
    # in place, because the match engine is holding on to them too.
    def restore(pantry_state, recipe_state)
      (@pantry.to_h.keys - pantry_state.keys).each { |name| @pantry.remove_item(name) }
      pantry_state.each { |name, item| restore_item(name, item) }
      (@recipe_book.to_h.keys - recipe_state.keys).each { |name| @recipe_book.delete(name) }
    end

    # Resets one pantry item to its saved amount.
    def restore_item(name, item)
      if @pantry.get_item(name)
        @pantry.update_item(name, item['quantity'], item['unit'])
      else
        @pantry.add_item(name, item['quantity'], item['unit'])
      end
    end
  end
end
