# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'named_validations/version'

Gem::Specification.new do |spec|
  spec.name          = 'named_validations'
  spec.version       = NamedValidations::VERSION
  spec.authors       = ['akira yamada']
  spec.email         = ['akira@arika.org']

  spec.summary       = 'Naming to ActiveModel/ActiveRecord validations'
  spec.description   = 'named_validations names to arguments of active_model\'s validates method.'
  spec.homepage      = 'https://github.com/arika/named_validations'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 11.0'
end
