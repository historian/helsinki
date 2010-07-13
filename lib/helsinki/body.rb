class Helsinki::Body

  attr_reader :path, :record

  def initialize(path_or_body, record=nil)
    @record     = record
    @processors = []
    if Pathname === path_or_body
      @path = path_or_body
    elsif path_or_body.respond_to?(:to_path)
      @path = path_or_body.to_path
    else
      @body = path_or_body
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

  def each(context=nil)
    if @body
      @body.each do |part|
        part = process_chunk(part, context)
        yield part if part
      end

    else
      F.open(@path, "rb") do |file|
        while part = file.read(8192)
          part = process_chunk(part, context)
          yield part if part
        end
      end
    end

    return self
  end

  private

  def process_chunk(chunk, context)
    @processors.each do |processor|
      chunk = processors.call(chunk, context)
      break unless chunk
    end
    chunk
  end
end
