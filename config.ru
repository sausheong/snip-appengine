%w(rubygems sinatra snip).each  { |lib| require lib}
root_dir = File.dirname(__FILE__)
set :environment, :production
set :root, root_dir
set :app_file, File.join(root_dir, 'snip.rb')
disable :run 
run Sinatra::Application