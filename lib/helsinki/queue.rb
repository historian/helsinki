class Helsinki::Queue

  def initialize
    @urls = []
    @processed_urls = Set.new
  end

  def push(url)
    unless @urls.include?(url) or @processed_urls.include?(url)
      @urls << url
    end

    true
  end

  def pop
    url = @urls.shift
    @processed_urls << url if url
    url
  end

  def empty?
    @urls.empty?
  end

end