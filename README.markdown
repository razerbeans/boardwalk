# About #

Boardwalk is a port of _why's Park Place (an S3 clone) to play nice with Ruby 
1.9, use the Sinatra web framework, and Mongo/MongoMapper for information and 
file storage.

# Requirements #
### The Basics ###
1. Ruby >= 1.9
2. MongoDB
3. Thin web server (currently the only server tested on)
3. Bundler

Necessary gems are listed in the Gemfile (bundler should take care of this).

# Troubleshooting #

While Boardwalk is still under heavy development (read: _incomplete_) you may
run into issues. Feel free to report these issues here with a log of the errors
you are receiving as well as information about your environment.

### NOTE: ###
Rack doesn't play nice with thin or webrick while running boardwalk. So 
until the issue is fixed, you will need to edit the following line in
rack/request.rb on your local machine (if you're having issues):
			
	def media_type
		content_type && content_type.split(/\s*[;,]\s*/, 2).first.downcase
	end
	
to..
			
	def media_type
		content_type && content_type.split(/\s*[;,]\s*/, 2).first#.downcase
	end
	
This should fix everything.