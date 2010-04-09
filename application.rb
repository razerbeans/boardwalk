LOCATION = File.join(File.dirname(__FILE__))
require 'rubygems'
require 'sinatra'
require 'mongo'
require 'mongo_mapper'
require "#{LOCATION}/lib/boardwalk.rb"

set :s3key, '44CF9590006BF252F707'
set :s3secret, 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV'
set :server, %w[mongrel webrick thin]
set :port, 3002
set :logging, true
set :show_exceptions, false

# BUFSIZE = (4 * 1024)
# STORAGE_PATH = File.join(Dir.pwd, 'storage')
# STATIC_PATH = File.expand_path('views/', File.dirname(__FILE__))
RESOURCE_TYPES = %w[acl torrent]
# CANNED_ACLS = {
#     'private' => 0600,
#     'public-read' => 0644,
#     'public-read-write' => 0666,
#     'authenticated-read' => 0640,
#     'authenticated-read-write' => 0660
# }
# READABLE = 0004
# WRITABLE = 0002
# READABLE_BY_AUTH = 0040
# WRITABLE_BY_AUTH = 0020

# use Boardwalk::Application
Boardwalk.run!