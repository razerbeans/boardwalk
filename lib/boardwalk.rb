module Sinatra
  class Request
    module AWSHandler
        def aws_authenticate
          # puts "Should do env loop."
          # puts @env.inspect
          @amz = {}
          @env.each do |k, v|
            # puts "Running env loop. (#{k}, #{v})"
            k = k.downcase.gsub('_', '-')
            # k = k.gsub('_', '-')
            @amz[$1] = v.strip if k =~ /^http-x-amz-([-\w]+)$/
          end
          date = (@env['HTTP_X_AMZ_DATE'] || @env['HTTP_DATE'])
          auth, key, secret = *@env['HTTP_AUTHORIZATION'].to_s.match(/^AWS (\w+):(.+)$/)
          uri = @env['PATH_INFO']
          uri += "?" + @env['QUERY_STRING'] if RESOURCE_TYPES.include?(@env['QUERY_STRING'])
          canonical = [@env['REQUEST_METHOD'], @env['HTTP_CONTENT_MD5'], @env['HTTP_CONTENT_TYPE'], date, uri]
          @amz.sort.each do |k, v|
              canonical[-1,0] = "x-amz-#{k}:#{v}"
          end
          # PSEDUO: If the user sent secret string is equal to the user's 
          #         [encrypted] information from the server, user is clear.
          #         otherwise, user is not allowed.
          # TODO: Remove User.new!
          # @user = Boardwalk::Models::User.find_by_key key
          # @user = User.new(key)
          # if @user and secret != hmac_sha1(options.s3secret, canonical.map{|v|v.to_s.strip} * "\n")
          @user = User.first(:conditions => {:s3key => key})
          # puts "*** USER SET AS: "+@user.inspect+" ***"
          # if @user.nil?
          #   throw :halt, [500, "User not set?"]
          # end
          # puts "Secret: "+secret+"\nDigest: "+hmac_sha1(@user.s3secret, canonical.map{|v|v.to_s.strip} * "\n")
          if @user and secret != hmac_sha1(@user.s3secret, canonical.map{|v|v.to_s.strip} * "\n")
             raise BadAuthentication
          end
        end
      private
        def hmac_sha1(key, s)
          return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
        end     
    end
  end
  helpers Request::AWSHandler
end

class Boardwalk < Sinatra::Base
    use Rack::FiberPool
    load 'lib/boardwalk/mimetypes.rb'
    load 'lib/boardwalk/control_routes.rb'
    load 'lib/boardwalk/helpers.rb'
    load 'lib/boardwalk/errors.rb'
    helpers Sinatra::Request::AWSHandler
    load 'lib/boardwalk/s3_routes.rb'
end