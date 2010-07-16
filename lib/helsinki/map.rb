class Helsinki::Map

  def draw(&block)
    Mapper.new(self).instance_eval(&block)
  end

  def initialize
    @root_set         = Set.new
    @ignored_patterns = Set.new
    @allowed_domains  = Set.new
  end

  attr_reader :root_set, :ignored_patterns, :allowed_domains

  LOCALHOST = URI.parse('http://localhost:80').normalize

  def enqueue(queue)
    @root_set.each do |url|
      queue.push url
    end
  end

  def normalize_url(url, base=nil)
    unless URI === url
      url = URI.parse(url.to_s)
    end

    url = (base || LOCALHOST).merge(url)
    url.normalize!
    url.fragment = nil

    url
  rescue URI::InvalidURIError
    return nil
  end

  def include?(url)
    return false unless url

    url_string = url.to_s

    pass = @allowed_domains.any? do |domain|
      case domain
      when Regexp
        url.host =~ domain

      when Proc
        !(FalseClass === domain.call(url))

      end
    end
    return false unless pass

    @ignored_patterns.each do |pattern|
      case pattern
      when Regexp
        if url_string =~ pattern
          return false
        end

      when Proc
        if TrueClass === pattern.call(url)
          return false
        end

      end
    end

    return true
  end

  class Mapper

    def initialize(map)
      @map = map
    end

    def visit(url)
      url = @map.normalize_url(url)
      @map.root_set << url

      self
    end

    def domain(*domains, &block)
      domains << block

      domains.flatten.compact.each do |domain|
        case domain
        when Regexp
          @map.allowed_domains << domain
        when String
          domain = domain.sub(/^www\./, '')
          domain = %r{^(?:www\.)?#{Regexp.escape(domain)}$}
            @map.allowed_domains << domain
        when Proc
          @map.allowed_domains << domain
        end
      end

      self
    end

    def ignore(pattern=nil, &block)
      case pattern || block
      when String
        pattern = Regexp.new(Regexp.escape(pattern))
      when Regexp
        pattern = pattern
      when Proc
        pattern = pattern
      else
        raise ArgumentError, "expects a String, Regexp or Proc"
      end

      @map.ignored_patterns << pattern

      self
    end

  end

end
