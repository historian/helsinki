class Helsinki::ConfigurationMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    if  env['helsinki.active'] == true  \
    and env['REQUEST_METHOD']  == 'GET' \
    and env['PATH_INFO']       == '/_helsinki/configuration'
      config = Rails::Application.config.helsinki
      [200, {}, {
        :map          => config.mapping,
        :store_config => {
          :database_path => config.store_config.database_path,
          :public_root   => config.store_config.public_root
        }
      }]
    else
      @app.call(env)
    end
  end

end