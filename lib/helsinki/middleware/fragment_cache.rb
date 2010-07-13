class Helsinki::Middleware::FragmentCache < Helsinki::Middleware::BaseCache

  def model_class
    Helsinki::Store::Fragment
  end

  def cache_prefix
    :fragment
  end

end
