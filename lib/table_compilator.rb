require "active_support"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash"
require "action_view"
require "memoist"

# NOTE: reference_parser must be installed by consuming applications
begin
  Gem::Specification.find_by_name("reference_parser")
  require "reference_parser"
rescue Gem::LoadError
end

require_relative "table_compilator/all"

module TableCompilator
  def self.root
    @root ||= File.expand_path("..", __dir__)
  end
end
