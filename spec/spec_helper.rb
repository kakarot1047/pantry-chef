# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  skip '/spec/'
  enable_coverage :branch
end

Dir[File.expand_path('../lib/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.mock_with(:rspec) { |m| m.verify_partial_doubles = true }
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
