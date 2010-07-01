module Helsinki

  require 'helsinki/version'
  require 'helsinki/map'
  require 'helsinki/queue'
  require 'helsinki/visitor'
  require 'helsinki/railtie'
  require 'helsinki/cache'
  require 'helsinki/middleware'

  def self.test_run!
    Helsinki::Map.draw do
      visit '/applications'
    end

    map   = Helsinki::Map.instance
    cache = Helsinki::Cache::FileSystem.new
    v = Helsinki::Visitor.new(map, cache)
    v.visit_all!
  end

end