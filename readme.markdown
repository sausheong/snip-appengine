Amidst the wretched events that happened at work recently, I forgot about an interesting development in running apps on a cloud. Google AppEngine finally released Java support on the AppEngine platform (http://googleappengine.blogspot.com/2009/04/seriously-this-time-new-language-on-app.html). For those uninitiated, AppEngine is Google's cloud computing platform that allows developers to serve up applications on Google's infrastructure. When it was first released in April 2008, the only language supported was Python. Python is a great language but doesn't appeal to my inner Rubyist so it didn't catch my attention. Until now that is.

While Java is no longer my language of choice nowadays, Ruby actually runs pretty well under JRuby with Java. And with the addition of the Java support for AppEngine, it became a lot more interesting. A few weeks back I wrote Snip, a TinyURL clone, in about 40 lines of Ruby code, and deployed it on Heroku. It seems like a good idea to take Snip out for a spin on the Google AppEngine for Java (GAE/J).

The first thing you need to do is to create an application on the GAE/J. Start by going to this URL - http://appengine.google.com/start and log in using a Google account. After logging in, create a new application following the instructions given on the screen. When you're done you should have an application id. In this case, it is 'saush-snip'. We will be needing this application id in our configuration later. You will also need to enable Java for your GAE/J. At this point in time, GAE/J is still in beta and Google is only limiting the first 10,000 developers from enabling Java for GAE/J (http://googleappengine.blogspot.com/2009/04/seriously-this-time-new-language-on-app.html). Unfortunately if you don't get Java enabled for your account, you won't be able to try this out until it is fully released and available to all. 

First thing we need to do is to install JRuby, if you haven't done so yet. Even if you have installed it previously you might want to install at least 1.3.0RC1 since some fixes to make it run better under GAE/J.

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ git clone git://github.com/jruby/jruby.git
</pre> 

This will clone a copy of JRuby into your computer. Then go into the jruby folder that was just created and run this:

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ sudo ant && sudo ant jar-complete
</pre>

This will install JRuby and create the jruby-complete.jar library that you will need in a while. Take note of this path to JRuby, you'll need it in the subsequent commands. Assume that you just installed JRuby in ~/jruby, do a quick check to see if the install is ok:

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ ~/jruby/bin/jruby -v
</pre>

If you installed version 1.3.0RC1 you should see something like this:

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
jruby 1.3.0RC1 (ruby 1.8.6p287) (2009-05-11 6586) (Java HotSpot(TM) 64-Bit Server VM 1.6.0_07) [x86_64-java]
</pre>

After installing JRuby, you'll need to install all gems that you need. Remember that even if you have installed gems for your normal Ruby installation you'll need to install it all over again for JRuby. For Snip, I need Sinatra and HAML, but you'll also need Rake and Warbler, the JRuby war file packager (http://caldersphere.rubyforge.org/warbler/).

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ ~/jruby/bin/jruby -S gem install rake sinatra haml warbler
</pre>

Now that the basic JRuby and related gems are done, let's look at the Snip code itself. One thing that is pretty obvious upfront when dealing with AppEngine is that it doesn't have a relational database for persistence. Instead of a familiar RDBMS, we get a JDO interface or a DataStore API. How do we use it? As it turns out, we don't need to do anything major. Ola Bini wrote a small wrapper around DataStore, called Bumble (http://olabini.com/blog/2009/04/jruby-on-rails-on-google-app-engine/), to allow us to write data models just like we did with DataMapper. Well, almost.

Using Bumble is very much similar to DataMapper and ActiveRecord, so I didn't have to change my code much. This is the DataMapper version of the Url model:

<pre>
[source language='ruby']
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'mysql://root:root@localhost/snip')
class Url
  include DataMapper::Resource
  property  :id,          Serial
  property  :original,    String, :length => 255
  property  :created_at,  DateTime  
  def snipped() self.id.to_s(36) end  
end
[/source]
</pre>

And this is the Bumble version of the Url model:
<pre>
[source language='ruby']
class Url
  include Bumble
  ds :original
  def snipped() self.key.to_s end  
end
[/source]
</pre>

I didn't add in the time stamp for the Bumble version because I don't really use it but as you can see there are quite a bit of similarities. I didn't need to put in my own running serial id because it's managed by the AppEngine. Also, instead of using the object id, I used the object's key, which again is managed by the AppEngine. A key is a unique identifier of an entity across all apps belonging to the user. The key is created automatically by Bumble through the low-level DataStore Java APIs. Besides this, using the Url class is slightly different also. Instead of

<pre>
[source language='ruby']
@url = Url.first(:original => uri.to_s)
[/source]
</pre>

We use: 
<pre>
[source language='ruby']
@url = Url.find(:original => uri.to_s)
[/source]
</pre>

Finally because we don't use the id anymore and use the key instead, we don't need to do the base 36 conversion and let the AppEngine handle everything. Instead of:

<pre>
[source language='ruby']
get '/:snipped' do redirect Url[params[:snipped].to_i(36)].original end
[/source]
</pre>

We use:
<pre>
[source language='ruby']
get '/:snipped' do redirect Url.get(params[:snipped]).original end
[/source]
</pre>

This is the full source code:

<pre>
[source language='ruby']
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
[/source]
</pre>

The code is ready but here comes the packaging. GAE/J is a Java servlet environment, which means our app needs to be packaged into a war. Fortunately instead of building up the war by hand we can use Warbler, the JRuby war packager. Before running Warbler, we need to have a couple of things. Firstly we need to build the warble configuration file:

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ mkdir config
$ ~/jruby/bin/jruby -S warble config
</pre>

We create a directory called config and get Warbler to copy a default configuration file to it. Replace the contents with this minimal setup. If you want to explore more, read warble.rb itself. 

<pre>
[source language='ruby']
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
[/source]
</pre>

Note that we don't really need the public and view directories in Snip because everything is in a single file. The 2 other configuration files we will need are appengine-web.xml and config.ru. We need to include the snip.rb and bumble.rb into the war file for deployment. To get bumble.rb, go to Ola Bini's Bumble GitHub repository (http://github.com/olabini/bumble) and get the file that is in the sub-folder (not the main one). The last line tells us not to include the jruby-complete.jar library in the lib folder when we run Warbler. I'll explain this in a minute. Also note the war file is the application id of the application we created in the GAE admin console earlier on (saush-snip).

Next, create a lib folder. Go to the GAE/J download site (http://code.google.com/appengine/downloads.html) and download the GAE/J Java library. It should be called something like appengine-api-1.0-sdk-1.2.0.jar. Copy that into the lib folder you've just created. We will also need the Java libraries in the lib folder. Normally for a JRuby deployment, Warbler will package it in, but Google has a 1,000 file limit which Ola Bini kindly pointed out. He also provided a script to split the JRuby library into 2 files. You can find the script here (http://olabini.com/blog/2009/04/jruby-on-rails-on-google-app-engine/) and when you run it, it should split jruby-complete.jar into 2 files named jruby-core-1.3.0RC1.jar and jruby-stdlib-1.3.0RC1.jar. You will also need JRuby-Rack (http://kenai.com/projects/jruby-rack/pages/Home) but it's included in Warbler and as you will see later, Warbler will copy it into the war when you run it. JRuby-Rack is an adapter for the Java servlet environment that allows Sinatra (or any Rack-based application) to run.

The next piece is appengine-web.xml. I used Ola Bini's version as the base:

<pre>
[source language='xml']
<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
    <application>saush-snip</application>
    <version>1</version>
    <static-files />
    <resource-files />
    <sessions-enabled>false</sessions-enabled>
    <system-properties>
      <property name="jruby.management.enabled" value="false" />
      <property name="os.arch" value="" />
      <property name="jruby.compile.mode" value="JIT"/> <!-- JIT|FORCE|OFF -->
      <property name="jruby.compile.fastest" value="true"/>
      <property name="jruby.compile.frameless" value="true"/>
      <property name="jruby.compile.positionless" value="true"/>
      <property name="jruby.compile.threadless" value="false"/>
      <property name="jruby.compile.fastops" value="false"/>
      <property name="jruby.compile.fastcase" value="false"/>
      <property name="jruby.compile.chainsize" value="500"/>
      <property name="jruby.compile.lazyHandles" value="false"/>
      <property name="jruby.compile.peephole" value="true"/>
			<property name="jruby.rack.logging" value="stdout"/>
   </system-properties>
</appengine-web-app>
[/source]	
</pre>

The list row in the property line sets logging to STDOUT, which is very useful for debugging. If you don't set this, you might not be able to see any console output. Again, we need to set the application id that we got earlier on (saush-snip).

Finally we need a config.ru Rackup file to start the whole thing:

<pre>
[source language='ruby']
%w(rubygems sinatra snip).each  { |lib| require lib}
root_dir = File.dirname(__FILE__)
set :environment, :production
set :root, root_dir
set :app_file, File.join(root_dir, 'snip.rb')
disable :run 
run Sinatra::Application	
[/source]
</pre>

You can of course also find all these things in the Snip-AppEngine repository at git://github.com/sausheong/snip-appengine.git. However it is so much more fun to do it step by step right?

Now that we have all the pieces let's package our files for deployment. First we need to generate the exploded war file:

<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ ~/jruby/bin/jruby -S warble
</pre>

You should see output like this:
<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
mkdir -p tmp/war/WEB-INF/gems/specifications
cp /Users/saush/jruby/lib/ruby/gems/1.8/specifications/sinatra-0.9.1.1.gemspec tmp/war/WEB-INF/gems/specifications/sinatra-0.9.1.1.gemspec
mkdir -p tmp/war/WEB-INF/gems/gems
JRuby limited openssl loaded. gem install jruby-openssl for full support.
http://wiki.jruby.org/wiki/JRuby_Builtin_OpenSSL
cp /Users/saush/jruby/lib/ruby/gems/1.8/specifications/rack-0.9.1.gemspec tmp/war/WEB-INF/gems/specifications/rack-0.9.1.gemspec
cp /Users/saush/jruby/lib/ruby/gems/1.8/specifications/haml-2.0.9.gemspec tmp/war/WEB-INF/gems/specifications/haml-2.0.9.gemspec
mkdir -p tmp/war/WEB-INF/lib
mkdir -p tmp/war/WEB-INF/public
mkdir -p tmp/war/WEB-INF/views
cp lib/appengine-api-1.0-sdk-1.2.0.jar tmp/war/WEB-INF/lib/appengine-api-1.0-sdk-1.2.0.jar
cp lib/jruby-core-1.3.0RC1.jar tmp/war/WEB-INF/lib/jruby-core-1.3.0RC1.jar
cp lib/jruby-stdlib-1.3.0RC1.jar tmp/war/WEB-INF/lib/jruby-stdlib-1.3.0RC1.jar
cp appengine-web.xml tmp/war/WEB-INF/appengine-web.xml
cp snip.rb tmp/war/WEB-INF/snip.rb
cp config.ru tmp/war/WEB-INF/config.ru
cp bumble.rb tmp/war/WEB-INF/bumble.rb
cp /Users/saush/.gem/jruby/1.8/gems/warbler-0.9.13/lib/jruby-rack-0.9.4.jar tmp/war/WEB-INF/lib/jruby-rack-0.9.4.jar
cp /Users/saush/.gem/jruby/1.8/gems/warbler-0.9.13/lib/jruby-rack-0.9.4.jar tmp/war/WEB-INF/lib/jruby-rack-0.9.4.jar
mkdir -p tmp/war/WEB-INF
jar cf saush-snip.war  -C tmp/war .
</pre>

You will also get a saush-snip.war file and a bunch of files under the tmp folder, which is really just the war file exploded. We won't need the war file itself for deployment, only the tmp directory. Before doing the deployment, we need to make a minor adjustment to the mp/war/WEB-INF/gems/gems/sinatra-0.9.1.1/lib/sinatra.rb file. Somehow the line 'use_in_file_templates!' gives an error when deploying to the GAE/J so comment it out (it doesn't do any harm).

That's it! We are ready for the deployment. To deploy run this command:


<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
$ ~/appengine-java-sdk-1.2.0/bin/appcfg.sh --email=<YOUR EMAIL> --passin update tmp/war/
</pre>

You should see output like this:
<pre style="background:black none repeat scroll 0 0; border-left:4px solid #666666; color:#CCCCCC; display:block; font-family:Monaco,monospace; padding:4px 4px 4px 8px; margin: 4px 4px 4px 8px; white-space:pre;overflow:auto;">
Reading application configuration data...
2009-05-15 19:51:38.916::INFO:  Logging to STDERR via org.mortbay.log.StdErrLog
Beginning server interaction for saush-snip...
Password for <YOUR EMAIL>: <YOUR PASSWORD>
0% Creating staging directory
5% Scanning for jsp files.
20% Scanning files on local disk.
25% Scanned 250 files.
28% Initiating update.
31% Cloning 340 application files.
33% Cloned 100 files.
34% Cloned 200 files.
35% Cloned 300 files.
40% Uploading 0 files.
90% Deploying new version.
95% Will check again in 1 seconds
98% Will check again in 2 seconds
99% Closing update: new version is ready to start serving.
99% Uploading index definitions.
Update complete.
Success.
Cleaning up temporary files...
</pre>

Now go to http://saush-snip.appspot.com and you should be able to see the new deployment of Snip on the Google AppEngine for Java. 

A few other tutorials on the Internet also describe how to deploy Sinatra or Rails-based apps on GAE/J, amongst which Samuel Goebert’s tutorial (http://blog.bigcurl.de/2009/04/running-sinatra-apps-on-google.html) and Ola Bini’s stand out the most.

A few thoughts on comparing Heroku and GAE/J since I’ve deployed on both of them now. Heroku is definitely the easier platform to deploy, with a just few simple steps compared to the hoops I had to jump for GAE/J. Heroku also has the arguably more familiar persistence mechanism as it uses the familiar RDBMS (postgresql) compared to Google’s DataStore implementation, which today only has Ola Bini’s Bumble implementation compared to the established ActiveRecord, DataMpper and Sequel ORMs. In addition, Google’s implementation has many limitations, some harder to understand than others, which forces applications to suit this platform rather than having the platform really service the application.

On the other hand, Google’s set of tools in its console is really impressive, with graphs of usage, data and log viewers. Google AppEngine also has memcached, url fetcher, integration with Google accounts, sending out mails and hosts of other helper services. Also, Google’s brand name does add some weight when you throw in more mission critical projects though Heroku, backed by Amazon’s EC2 services is no push-over (http://venturebeat.com/2009/04/23/heroku-rolls-out-business-model-to-painlessly-deploy-rails-apps/).  As for costs, until large deployments emerge it is hard to say which is the better deal, also it really depends highly on usage patterns.

So are they evenly balanced out? For now I would still favor Heroku over GAE/J because Heroku is more friendly to Ruby developers. But who knows? It’s exciting times for Rubyists.