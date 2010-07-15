class Helsinki::ConfigurationMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    if    env['helsinki.active'] == true  \
      and env['REQUEST_METHOD']  == 'GET' \
      and env['PATH_INFO']       == '/_helsinki/configuration'
      config = Rails.configuration.helsinki
      [200, {}, {
        :map          => config.mapping,
        :recorder     => Helsinki::QueryRecorder.new,
        :store_config => {
        :database_path => config.database_path,
        :public_root   => config.public_root,
        :private_root  => config.private_root
      }
      }]
    else
      @app.call(env)
    end
  end

end
