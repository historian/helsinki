class Helsinki::Queue

  def initialize
    @urls = []
    @skip_list = Set.new
  end

  def push(url)
    if @skip_list.include?(url)
      return false
    end

    if Helsinki::Store::Page.first(:url => url)
      @skip_list << url
      return false
    end

    unless @urls.include?(url)
      @skip_list << url
      @urls << url
    end

    true
  end

  def pop
    @urls.shift
  end

  def empty?
    @urls.empty?
  end

end
