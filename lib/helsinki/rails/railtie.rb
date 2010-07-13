require 'helsinki/map'
require 'helsinki/rails/configuration_middleware'

class Helsinki::Railtie < Rails::Railtie

  config.helsinki         = ActiveSupport::OrderedOptions.new
  config.helsinki.mapping = Helsinki::Map.new
  config.helsinki.store_config = ActiveSupport::OrderedOptions.new
  config.helsinki.store_config.database_path = 'db/helsinki.db'
  config.helsinki.store_config.public_root   = 'public'
  config.helsinki.store_config.private_root  = 'db/cache'

  initializer "helsinki.load_map" do |app|

    maps = []
    railties = [app.railties.all, app].flatten
    railties.each do |railtie|
      next unless railtie.respond_to? :paths
      maps.concat(
        railtie.paths.config.helsinki.to_a)
    end

    config.helsinki.mapping = Helsinki::Map.new
    maps.each do |map|
      Kernel.load(map)
    end

  end

  initializer "helsinki.register_middleware" do |app|
    app.middleware.insert_before 'ActionDispatch::Static', 'Helsinki::ConfigurationMiddleware'
  end

end

class Rails::Engine::Configuration

  alias_method :paths_without_helsinki, :paths

  def paths
    @paths ||= begin
                 paths_without_helsinki
                 @paths.config.helsinki "config/helsinki.rb"
                 @paths
               end
  end

end

class Rails::Application
  def helsinki
    config.helsinki.mapping
  end
end
