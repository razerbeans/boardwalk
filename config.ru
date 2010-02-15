require "application.rb"

##
# Not entirely certain how all of this fits into the program. Looks like 
# command/global ARGs. Most interested in info about ACLS and BUFSIZE.
##
VERSION = "0.0.1"
BUFSIZE = (4 * 1024)
STORAGE_PATH = File.join(Dir.pwd, 'storage')
STATIC_PATH = File.expand_path('views/', File.dirname(__FILE__))
RESOURCE_TYPES = %w[acl torrent]
CANNED_ACLS = {
    'private' => 0600,
    'public-read' => 0644,
    'public-read-write' => 0666,
    'authenticated-read' => 0640,
    'authenticated-read-write' => 0660
}
READABLE = 0004
WRITABLE = 0002
READABLE_BY_AUTH = 0040
WRITABLE_BY_AUTH = 0020

##
# Sinatra config stuff.
##
set :environment, :development
set :sessions, true
set :logging, true

# use Boardwalk::Application
run Sinatra::Base