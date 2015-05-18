# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'date'
require "geocoder/olleh/version"

Gem::Specification.new do |s|
  s.name        = "geocoder_olleh"
  s.required_ruby_version = '>= 1.9.3'
  s.version     = Geocoder::Olleh::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kim Jaigouk"]
  s.email       = ["ping@jaigouk.kim"]
  s.homepage    = "http://www.rubygeocoder.com"
  s.date        = Date.today.to_s
  s.summary     = "Geocoder + Olleh"
  s.description = "Extends Geocoder to use the Olleh maps API"
  s.files       = Dir['LICENSE', 'README.md', 'lib/**/*']
  s.require_paths = ["lib"]
  s.license     = 'MIT'

  s.add_dependency 'geocoder'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'
end
