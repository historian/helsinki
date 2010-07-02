class Helsinki::Cache::FileSystem < Helsinki::Cache::Base

  def initialize(options={})
    @public_root = File.expand_path(
      options[:public_root] || 'public/cache', Rails.root)
    @private_root = File.expand_path(
      options[:private_root] || 'tmp/cache', Rails.root)
    @metadata_root = File.expand_path(
      options[:metadata_root] || 'tmp/cache', Rails.root)
  end

  def store(env, response)

    status, headers, body = *response

    cache_path = cache_path(env, headers)
    FileUtils.mkdir_p(File.dirname(cache_path))
    File.open(cache_path, 'w+', 0644) do |file|
      body.each do |chunk|
        file.write chunk
      end
    end

    metadata_path = cache_path(env, headers, true)
    FileUtils.mkdir_p(File.dirname(metadata_path))
    File.open(metadata_path, 'w+', 0600) do |file|
      file.write YAML.dump(env['helsinki.metadata'])
    end

    true
  end

  def fetch(env)

  end

private

  def cache_path(env, headers, metadata=false)
    url  = env['helsinki.url']
    priv = url.path.starts_with?('/_private')

    path = url.path[1..-1]
    if path == '' or path.ends_with?('/')
      type = headers['Content-Type'].split(';').first
      extention = Mime::Type.lookup(type).to_sym
      path = File.join(path, "index.#{extention}")

    elsif !File.basename(path).include?('.')
      type = headers['Content-Type'].split(';').first
      extention = Mime::Type.lookup(type).to_sym
      path = "#{path}.#{extention}"

    end

    if metadata
      base = @metadata_root
      path = path += ".info"
    elsif priv
      base = @private_root
    else
      base = @public_root
    end

    File.join(
      base,
      "#{url.host}_#{url.port}",
      path)
  end

end