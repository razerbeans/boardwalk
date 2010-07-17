class Boardwalk < Sinatra::Base
    use Rack::FiberPool
    load 'lib/boardwalk/mimetypes.rb'
    load 'lib/boardwalk/control_routes.rb'
    load 'lib/boardwalk/helpers.rb'
    load 'lib/boardwalk/errors.rb'
    load 'lib/boardwalk/s3_routes.rb'
end