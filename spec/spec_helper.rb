# frozen_string_literal: true

# Shared setup for every spec, loaded by the --require option in .rspec.
# Start coverage before loading the application so its executed lines are recorded.
require 'simplecov'
SimpleCov.start do
  # Measure application code and fail the suite if coverage falls below 80 percent.
  add_filter '/spec/'
  minimum_coverage 80
end

# Enumerate the directory explicitly: absolute globs can miss files on Windows.
library_directory = File.expand_path('../lib', __dir__)
Dir.children(library_directory).grep(/\.rb\z/).sort.each do |filename|
  require File.join(library_directory, filename)
end

RSpec.configure do |config|
  # Use expect(...) assertions and include chained matcher details in failure messages.
  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  # Stubs on real objects must refer to methods those objects actually provide.
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.shared_context_metadata_behavior = :apply_to_host_groups
  # Remember example results so RSpec can rerun failed examples with --only-failures.
  config.example_status_persistence_file_path = 'spec/examples.txt'
  # Random order exposes tests that depend on each other; the printed seed allows a rerun.
  config.order = :random
  Kernel.srand config.seed
end
