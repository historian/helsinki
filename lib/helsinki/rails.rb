if defined?(Rails::Railtie)
  # Rails 3.x
  require 'helsinki/rails3/railtie'
  require 'helsinki/rails3/query_recorder'
  require 'helsinki/rails3/configuration_middleware'

else
  # Rails 2.0
  require 'helsinki/rails2/initializer'
  require 'helsinki/rails2/query_recorder'
  require 'helsinki/rails2/configuration_middleware'

end
