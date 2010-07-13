require 'thor'
require 'eventmachine'

class Helsinki::CLI < Thor
  namespace :default

  desc "start", "start the helsinki server"
  method_option :socket, :type => :string,
    :default => (ENV['HELSINKI_SOCK'] || '/tmp/helsinki.sock')
  method_option :config, :type => :string,
    :default => (ENV['HELSINKI_CONF'] || '/etc/helsinki.conf')
  method_option :foreground, :type => :boolean,
    :default => false
  def start
    unless options.foreground
      if RUBY_VERSION < '1.9'
        exit if fork
        Process.setsid
        exit if fork
      else
        Process.daemon(true, true)
      end
    end

    trap('INT') { puts ; EM.stop_event_loop }
    $cmd = $0
    $0 = "Helsinki server: #{options.socket}"

    EM.run do
      puts "Listening on #{options.socket}"
      EM.start_unix_domain_server(options.socket, Helsinki::Server, options)
    end

  ensure
    puts "bye."
    File.unlink(options.socket) if File.exist?(options.socket)
  end

  desc "stop", "stop the helsinki server"
  method_option :socket, :type => :string,
    :default => (ENV['HELSINKI_SOCK'] || '/tmp/helsinki.sock')
  def stop
    EM.run do
      client = EM.connect_unix_domain(options.socket, Helsinki::Client)
      client.stop_server
    end
  end

  desc "restart", "restart the helsinki server"
  method_option :socket, :type => :string,
    :default => (ENV['HELSINKI_SOCK'] || '/tmp/helsinki.sock')
  def restart
    EM.run do
      client = EM.connect_unix_domain(options.socket, Helsinki::Client)
      client.restart_server
    end
  end

  desc "load APP [ENV]", "load a rack application"
  method_option :socket, :type => :string,
    :default => (ENV['HELSINKI_SOCK'] || '/tmp/helsinki.sock')
  def load(app, env=nil)
    app = File.expand_path(app)
    env = env || ENV['HELSINKI_ENV'] || 'development'

    EM.run do
      client = EM.connect_unix_domain(options.socket, Helsinki::Client)
      client.load(app, env)
    end
  end

  desc "unload APP", "unload a rack application"
  method_option :socket, :type => :string,
    :default => (ENV['HELSINKI_SOCK'] || '/tmp/helsinki.sock')
  def unload(app, env=nil)
    app = File.expand_path(app)

    EM.run do
      client = EM.connect_unix_domain(options.socket, Helsinki::Client)
      client.unload(app)
    end
  end

  desc "build APP", "lobuildad a rack application"
  method_option :socket, :type => :string,
    :default => (ENV['HELSINKI_SOCK'] || '/tmp/helsinki.sock')
  def build(app, env=nil)
    app = File.expand_path(app)

    EM.run do
      client = EM.connect_unix_domain(options.socket, Helsinki::Client)
      client.build(app)
    end
  end

end