# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'date'
require 'geocoder/olleh/version'

Gem::Specification.new do |spec|
  spec.name          = "geocoder-olleh"
  spec.version       = Geocoder::Olleh::VERSION
  spec.authors       = ["Jaigouk Kim"]
  spec.email         = ["ping@jaigouk.kim"]

  spec.summary       = %q{geocoding with Olleh map api}
  spec.description   = %q{Provides object geocoding}
  spec.homepage      = "https://github.com/jaigouk/geocoder-olleh"
  spec.license       = "MIT"
  spec.date          = Date.today.to_s

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
