class Helsinki::Middleware::PageCache < Helsinki::Middleware::BaseCache

  def model_class
    Helsinki::Store::Page
  end

  def cache_prefix
    :page
  end

end
