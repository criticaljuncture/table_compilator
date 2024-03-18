require_relative "lib/table_compilator/version"

Gem::Specification.new do |spec|
  spec.name = "table_compilator"
  spec.version = TableCompilator::VERSION
  spec.authors = [""]
  spec.email = [""]

  spec.summary = "Common public table parsing & rendering."
  spec.description = "Common public table parsing & rendering."
  spec.homepage = "https://github.com/criticaljuncture/table_compilator"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/criticaljuncture/table_compilator"
  spec.metadata["changelog_uri"] = "https://github.com/criticaljuncture/table_compilator"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack"
  spec.add_dependency "actionview"
  spec.add_dependency "activesupport"
  spec.add_dependency "htmlentities"
  spec.add_dependency "memoist"
  spec.add_dependency "reference_parser"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "parallel_tests"
  spec.add_development_dependency "rainbow"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-html-matchers"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop", ">= 1.29.1"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "standard", ">= 1.12.1"
  spec.add_development_dependency "turbo_tests"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
