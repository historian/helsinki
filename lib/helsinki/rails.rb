if defined?(Rails::Railtie)
  # Rails 3.x
  require 'helsinki/rails3/railtie'
  require 'helsinki/rails3/query_recorder'

else
  # Rails 2.0
  require 'helsinki/rails2/query_recorder'
  require 'helsinki/rails2/initializer'

end
