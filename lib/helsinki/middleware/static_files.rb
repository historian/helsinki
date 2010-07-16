class Helsinki::Middleware::StaticFiles

  def initialize(app, static_root)
    @app, @static_root = app, static_root
  end

  def call(env)
    path  = File.join(@static_root, env['PATH_INFO'].chomp('/'))
    path  = File.join(path, 'index.html') if File.directory?(path)
    ext   = File.extname(path)
    path += (ext = '.html') unless ext
    mime  = Rack::Mime.mime_type(ext)

    if File.file?(path)
      [200, { 'Content-Type' => mime }, Helsinki::Body.new(Pathname.new(path))]
    else
      @app.call(env)
    end
  end

end
