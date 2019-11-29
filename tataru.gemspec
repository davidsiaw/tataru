# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tataru/version'

Gem::Specification.new do |spec|
  spec.name          = 'tataru'
  spec.version       = Tataru::VERSION
  spec.authors       = ['David Siaw']
  spec.email         = ['dsiaw@degica.com']

  spec.summary       = 'Task planner'
  spec.description   = 'Sworn upon the name of the receptionist'
  spec.homepage      = 'https://github.com/davidsiaw/tataru'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/davidsiaw/tataru'
    spec.metadata['changelog_uri'] = 'https://github.com/davidsiaw/tataru'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = Dir['lib/**/*.rb'] +
                       Dir['exe/*'] +
                       ['Rakefile']

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'bunny-tsort'
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
