Warbler::Config.new do |config|
	config.dirs = %w(lib public views)
	config.includes = FileList["appengine-web.xml", "snip.rb", "config.ru", "bumble.rb"]
	config.gems = ['sinatra', 'haml']
	config.gem_dependencies = true
	config.war_name = "saush-snip"
	config.webxml.booter = :rack
	config.webxml.jruby.init.serial = true
	config.java_libs.reject! { |lib| lib =~ /jruby-complete/ }
end