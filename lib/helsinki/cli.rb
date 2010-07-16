require 'thor'
require 'eventmachine'
require 'helsinki/version'
require 'helsinki/client'

class Helsinki::CLI < Thor
  namespace :default

  desc "start", "load an application"
  method_option :env, :type => :string,
    :default => (ENV['HELSINKI_ENV'] || 'development')
  method_option :dir, :type => :string,
    :default => Dir.pwd
  method_option :sock, :type => :string,
    :default => 'tmp/sockets/helsinki.sock'
  method_option :foreground, :type => :boolean,
    :default => false
  def start
    unless File.exist?(options.dir)
      shell.say_status('Error', "No such directory: #{options.dir}", :red)
      exit(1)
    end

    unless File.file?(File.join(options.dir, 'config.ru')) \
      or   File.file?(File.join(options.dir, 'config/environment.rb'))
      shell.say_status('Error', "Not a rack app: #{options.dir}", :red)
      exit(2)
    end

    if client.ping
      shell.say_status('Error', "Helsinki is already running for: #{options.dir}", :red)
      exit(3)
    end

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
    $0 = "Helsinki: #{options.dir}"
    is_worker = true

    options.dir  = File.expand_path(options.dir)
    options.sock = File.expand_path(options.sock, options.dir)
    rack_up      = File.expand_path('config.ru', options.dir)
    env_rb       = File.expand_path('config/environment.rb', options.dir)
    conf_rb      = File.file?(rack_up) ? rack_up : env_rb

    Dir.chdir(options.dir)
    File.unlink(options.sock) if File.exist?(options.sock)

    user = Etc.getpwuid(File.stat(conf_rb).uid).name
    EM.set_effective_user(user)

    FileUtils.mkdir_p(File.dirname(options.sock))

    ENV['RACK_ENV'] = ENV['RAILS_ENV'] = options.env

    if conf_rb == rack_up
      shell.say_status('Info', 'starting rack', :green)
      require 'rack'
      rack_app, _ = *Rack::Builder.parse_file(rack_up)
    else
      shell.say_status('Info', 'starting rails', :green)
      require 'config/environment'
      rack_app = ActionController::Dispatcher.new
    end

    # ensure helsinki is loaded
    require 'helsinki'

    EM.run do
      shell.say_status 'Info', "Started worker for: #{options.dir}", :green
      EM.start_unix_domain_server(options.sock, Helsinki::Worker, options, rack_app)
    end

  ensure
    if is_worker
      puts "bye."
      File.unlink(options.sock) if File.exist?(options.sock)
    end
  end

  desc "stop", "stop a helsinki app"
  method_option :dir, :type => :string,
    :default => Dir.pwd
  method_option :sock, :type => :string,
    :default => 'tmp/sockets/helsinki.sock'
  def stop
    client.stop
  end

  desc "restart", "restart the helsinki server"
  method_option :dir, :type => :string,
    :default => Dir.pwd
  method_option :sock, :type => :string,
    :default => 'tmp/sockets/helsinki.sock'
  def restart
    client.restart
  end

  desc "build", "start a build"
  method_option :dir, :type => :string,
    :default => Dir.pwd
  method_option :sock, :type => :string,
    :default => 'tmp/sockets/helsinki.sock'
  def build
    client.build
  end

  private

  def client
    sock_path = File.join(options.dir, options.sock)
    Helsinki::Client.new(sock_path)
  end

end
