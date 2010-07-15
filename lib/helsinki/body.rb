class Helsinki::Body

  attr_reader :path, :record
  attr_accessor :strategy

  def initialize(path_or_body, record=nil)
    @record     = record
    @processors = []
    if Pathname === path_or_body
      @path = path_or_body
      @strategy = :link
    elsif path_or_body.respond_to?(:to_path)
      @path = path_or_body.to_path
      @strategy = :link
    else
      @body = path_or_body
      @strategy = :write
    end
  end

  def processor(callback=nil, &block)
    callback ||= block
    @processors.push(callback)
    self
  end

  def respond_to?(m)
    (m.to_sym == :to_path ? !@path.nil? : super(m))
  end

  def to_path
    @path
  end

  def process!(record)
    unless @processors.empty? or @processed

      body = ""

      if @path
        body = File.read(@path)
      else
        @body.each { |chunk| body.concat(chunk) }
      end

      @processors.each do |processor|
        body = processor.call(body, record)
      end

      @body = [body]

      @processed = true
    end
  end

  def persist!(path, record)
    process!(record)

    FileUtils.mkdir_p(File.dirname(path))
    File.unlink(path) if File.exist?(path) or File.symlink?(path)

    case @strategy
    when :link
      src = File.join(Dir.pwd, @path.to_s)
      src = File.readlink(src) if File.symlink?(src)
      FileUtils.ln_s(src, path)

    when :write
      if @body
        File.open(path, 'w+', 0644) { |file| @body.each { |chunk| file.write chunk } }
      else
        FileUtils.cp(@path, path)
      end

    end

    @body     = nil
    @path     = path
    @record   = record
    @strategy = :link

    self
  end

  def persist(path, record)
    dup.persist!(path, record)
  end

  def read
    if @body
      @body
    else
      File.read(@path)
    end
  end

end
