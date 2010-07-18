# About #

Boardwalk is a port of _why's Park Place (an S3 clone) to play nice with Ruby 
1.9, use the Sinatra web framework, and MongoDB/MongoMapper for information and 
file storage.

# Requirements #
### The Basics ###
1. Ruby >= 1.9
2. Sinatra 1.0
3. MongoDB
4. Bundler

**Use Bundler to install any necessary gems.**

# Running #
To run boardwalk, in the root directory (`boardwalk/`), run:

	bin/boardwalk

# Customizing #
If you wish to learn more about customizing boardwalk, just type:

	bin/boardwalk --help

# Troubleshooting #

While Boardwalk is still under heavy development so you may
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