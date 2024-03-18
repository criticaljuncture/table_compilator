$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "action_controller"
require "table_compilator"
require "rspec-html-matchers"
require "spec_helper"
require "byebug"
require "rainbow"
require_relative "helpers/table_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  config.include RSpecHtmlMatchers
  config.include TableHelper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
