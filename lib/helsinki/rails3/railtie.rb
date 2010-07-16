require 'helsinki/map'

class Helsinki::Railtie < Rails::Railtie

  config.helsinki = ActiveSupport::OrderedOptions.new
  config.helsinki.recorder      = Helsinki::QueryRecorder.new
  config.helsinki.database_path = 'db/helsinki.db'
  config.helsinki.public_root   = 'public'
  config.helsinki.private_root  = 'db/cache'

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

  initializer "helsinki.add_assets_path" do |app|
    app.paths.public = 'app/assets'
  end

  initializer "helsinki.set_config" do
    Rails.helsinki.recorder      = config.helsinki.recorder
    Rails.helsinki.database_path = config.helsinki.database_path
    Rails.helsinki.public_root   = config.helsinki.public_root
    Rails.helsinki.private_root  = config.helsinki.private_root
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

module Rails
  def self.helsinki
    Helsinki::Configuration
  end
end
