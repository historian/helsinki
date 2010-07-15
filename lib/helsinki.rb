module Helsinki

  require 'helsinki/version'

  autoload :CLI,    'helsinki/cli'
  autoload :Client, 'helsinki/client'
  autoload :Worker, 'helsinki/worker'

  if defined?(Rails)
    require 'helsinki/rails'
  end

end
