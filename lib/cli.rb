# frozen_string_literal: true

require_relative 'validation_error'
require_relative 'storage'
require_relative 'recipe'

module PantryChef
  # Terminal menu. Holds no business rules; delegates to the domain objects it is constructed with.
  # Owner: Gokulan — "Build terminal CLI".
  class CLI
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

    EXIT_COMMANDS = %w[quit exit].freeze
    DEFAULT_MAX_MISSING = 2

    MENU = <<~MENU
      Pantry:   pantry | add <name> <qty> <unit> | update <name> <qty> [unit] | remove <name>
      Recipes:  recipes | show-recipe <name> | add-recipe <name> <servings> "<item qty unit>, ..."
      Matching: can-make | almost [n]
      Cooking:  cook <name>
      Other:    help | quit
    MENU

    def initialize(pantry:, recipe_book:, match_engine:, storage:, input: $stdin, output: $stdout)
      @pantry = pantry
      @recipe_book = recipe_book
      @match_engine = match_engine
      @storage = storage
      @input = input
      @output = output
    end

    def run
      @output.puts 'Pantry Chef. Type `help` for the menu.'
      loop do
        @output.print '> '
        line = @input.gets
        break if line.nil? || run_command(line) == :quit
      end
      @output.puts 'Goodbye.'
    end

    # Runs one line and returns :quit when the user asked to leave.
    # Every domain error is reported here so the loop never dies.
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

    def split_command(line)
      command, rest = line.to_s.strip.split(/\s+/, 2)
      return [nil, nil] if command.nil? || command.empty?

      [command.downcase, rest.to_s.strip]
    end

    def unknown(command)
      @output.puts "Unknown command '#{command}'. Type `help` for the menu."
    end

    def show_help(_rest)
      @output.puts MENU
    end

    def show_pantry(_rest)
      items = @pantry.items
      return @output.puts('Pantry is empty.') if items.empty?

      items.each { |name, item| @output.puts "  #{name}: #{item['quantity']} #{item['unit']}" }
    end

    def add_item(rest)
      name, quantity, unit = rest.split(/\s+/, 3)
      raise ValidationError, 'Usage: add <name> <qty> <unit>' if unit.nil?

      item = @pantry.add_item(name, quantity, unit)
      persist
      @output.puts "Stocked #{name}: #{item['quantity']} #{item['unit']}"
    end

    def update_item(rest)
      name, quantity, unit = rest.split(/\s+/, 3)
      raise ValidationError, 'Usage: update <name> <qty> [unit]' if quantity.nil?

      item = @pantry.update_item(name, quantity, unit)
      persist
      @output.puts "Updated #{name}: #{item['quantity']} #{item['unit']}"
    end

    def remove_item(rest)
      raise ValidationError, 'Usage: remove <name>' if rest.empty?

      item = @pantry.remove_item(rest)
      persist
      @output.puts "Removed #{rest} (was #{item['quantity']} #{item['unit']})"
    end

    def list_recipes(_rest)
      recipes = @recipe_book.all
      return @output.puts('No recipes yet.') if recipes.empty?

      recipes.each { |recipe| @output.puts "  #{recipe.name} (serves #{recipe.servings})" }
    end

    def show_recipe(rest)
      raise ValidationError, 'Usage: show-recipe <name>' if rest.empty?

      recipe = @recipe_book.find(rest)
      return @output.puts("Recipe not found: #{rest}") if recipe.nil?

      @output.puts "#{recipe.name} (serves #{recipe.servings})"
      recipe.ingredients.each { |name, need| @output.puts "  #{name}: #{need['quantity']} #{need['unit']}" }
    end

    def add_recipe(rest)
      name, servings, spec = rest.split(/\s+/, 3)
      raise ValidationError, 'Usage: add-recipe <name> <servings> "<item qty unit>, ..."' if spec.nil?

      recipe = Recipe.new(name: name, servings: servings, ingredients: parse_ingredients(spec))
      @recipe_book.add(recipe)
      persist
      @output.puts "Added recipe #{recipe.name}."
    end

    def parse_ingredients(spec)
      spec.delete('"').split(',').to_h do |part|
        name, quantity, unit = part.strip.split(/\s+/, 3)
        raise ValidationError, "Bad ingredient '#{part.strip}'. Use: <name> <qty> <unit>" if unit.nil?

        [name, { 'quantity' => quantity, 'unit' => unit }]
      end
    end

    def show_cookable(_rest)
      recipes = @match_engine.cookable_recipes
      return @output.puts('Nothing can be made right now.') if recipes.empty?

      recipes.each { |recipe| @output.puts "  #{recipe.name}" }
    end

    def show_almost(rest)
      max_missing = rest.empty? ? DEFAULT_MAX_MISSING : Integer(rest, exception: false)
      matches = @match_engine.almost_makeable(max_missing: max_missing)
      return @output.puts('Nothing is close.') if matches.empty?

      matches.each do |match|
        @output.puts "  #{match['recipe'].name} - missing #{format_shortages(match['shortages'])}"
      end
    end

    def format_shortages(shortages)
      shortages.map { |name, info| "#{name} (need #{info['shortage']} more #{info['unit']})" }.join(', ')
    end

    def cook(rest)
      raise ValidationError, 'Usage: cook <name>' if rest.empty?

      result = @match_engine.cook(rest)
      persist
      @output.puts "Cooked #{result['recipe'].name}. Used #{format_consumed(result['consumed'])}."
    end

    def format_consumed(consumed)
      consumed.map { |name, need| "#{name} #{need['quantity']} #{need['unit']}" }.join(', ')
    end

    def persist
      @storage.save(@pantry, @recipe_book)
    end
  end
end
