namespace :helsinki do

  task :clear do
  end

  task :build do
  end

  task :rebuild => [:clear, :build]

end