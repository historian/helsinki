# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bundler'
require 'helsinki/version'

Gem::Specification.new do |s|
  s.name        = "helsinki"
  s.version     = Helsinki::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Menke"]
  s.email       = ["simon.menke@gmail.com"]
  s.homepage    = "http://github.com/fd/helsinki"
  s.summary     = "--"
  s.description = "...---..."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "helsinki"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'

  s.executables = ['helsinki']

  s.add_bundler_dependencies
end
