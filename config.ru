require 'rubygems'
require 'sinatra'
 
root_dir = File.dirname(__FILE__)
 
set :environment, :production
set :root, root_dir
set :app_file, File.join(root_dir, 'snip.rb')
disable :run
 
require 'snip'
 
run Sinatra::Application