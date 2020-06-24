# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tataru/version'

Gem::Specification.new do |spec|
  unless spec.respond_to?(:metadata)
    # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host',
    # or delete this section to allow pushing this gem to any host.
    raise <<-ERR
      RubyGems 2.0 or newer is required to protect against public gem pushes.
    ERR
  end

  spec.name          = 'tataru'
  spec.version       = Tataru::VERSION
  spec.authors       = ['David Siaw']
  spec.email         = ['davidsiaw@gmail.com']

  spec.summary       = 'The greatest organizer'
  spec.description   = 'Tataru is a DSL for orchestrating the creation of resources'
  spec.homepage      = 'https://github.com/davidsiaw/tataru'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/davidsiaw/tataru'
  spec.metadata['changelog_uri'] = 'https://github.com/davidsiaw/tataru'

  spec.files = Dir['{exe,lib,bin}/**/*'] +
               %w[Gemfile tataru.gemspec]
  spec.test_files    = Dir['{spec,features}/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'bunny-tsort'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
end
