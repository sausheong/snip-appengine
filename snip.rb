%w(rubygems sinatra bumble uri).each  { |lib| require lib}

get '/' do haml :index end

post '/' do
  uri = URI::parse(params[:original])
  raise "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS
  @url = Url.find(:original => uri.to_s)
  @url = Url.create(:original => uri.to_s) if @url.nil?
  haml :index
end

get '/:snipped' do redirect Url.get(params[:snipped]).original end

error do haml :index end

use_in_file_templates!

class Url
  include Bumble
  ds :original
  def snipped() self.key.to_s end  
end

__END__

@@ layout
!!! 1.1
%html
  %head
    %title Snip! on Google AppEngine
    %link{:rel => 'stylesheet', :href => 'http://www.w3.org/StyleSheets/Core/Modernist', :type => 'text/css'}  
  = yield

@@ index
%h1.title Snip! on Google AppEngine
- unless @url.nil?
  %code= @url.original
  snipped to 
  %a{:href => env['HTTP_REFERER'] + @url.snipped}
    = env['HTTP_REFERER'] + @url.snipped
#err.warning= env['sinatra.error']
%form{:method => 'post', :action => '/'}
  Snip this:
  %input{:type => 'text', :name => 'original', :size => '50'} 
  %input{:type => 'submit', :value => 'snip!'}
%small copyright &copy;
%a{:href => 'http://blog.saush.com'}
  Chang Sau Sheong
%br
  %a{:href => 'http://github.com/sausheong/snip-appengine'}
    Full source code