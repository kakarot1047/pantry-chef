# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
<<<<<<< HEAD
  skip '/spec/'
  enable_coverage :branch
end

Dir[File.expand_path('../lib/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.mock_with(:rspec) { |m| m.verify_partial_doubles = true }
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
=======
  add_filter '/spec/'
  minimum_coverage 80
end

# Enumerate the directory explicitly: absolute globs can miss files on Windows.
library_directory = File.expand_path('../lib', __dir__)
Dir.children(library_directory).grep(/\.rb\z/).sort.each do |filename|
  require File.join(library_directory, filename)
end

RSpec.configure do |config|
  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.shared_context_metadata_behavior = :apply_to_host_groups
>>>>>>> origin/feature/bhaumik-pantry-storage
  config.order = :random
  Kernel.srand config.seed
end
