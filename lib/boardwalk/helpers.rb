helpers do
  def aws_authenticate
    @amz = {}
    @env.each do |k, v|
      k = k.downcase.gsub('_', '-')
      @amz[$1] = v.strip if k =~ /^http-x-amz-([-\w]+)$/
    end
    puts @env.inspect
    date = (@env['HTTP_X_AMZ_DATE'] || @env['HTTP_DATE'])
    auth, key, secret = *@env['HTTP_AUTHORIZATION'].to_s.match(/^AWS (\w+):(.+)$/)
    uri = @env['PATH_INFO']
    uri += "?" + @env['QUERY_STRING'] if RESOURCE_TYPES.include?(@env['QUERY_STRING'])
    canonical = [@env['REQUEST_METHOD'], @env['HTTP_CONTENT_MD5'], @env['HTTP_CONTENT_TYPE'], date, uri]
    @amz.sort.each do |k, v|
        canonical[-1,0] = "x-amz-#{k}:#{v}"
    end
    @user = User.first(:conditions => {:s3key => key})
    if @user and secret != hmac_sha1(@user.s3secret, canonical.map{|v|v.to_s.strip} * "\n")
       raise BadAuthentication
    end
  end
  
  def generate_secret
      abc = %{ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz} 
      (1..40).map { abc[rand(abc.size),1] }.join
  end

  def generate_key
      abc = %{ABCDEF0123456789} 
      (1..20).map { abc[rand(abc.size),1] }.join
  end
  
  def login_required
    if session[:user].nil?
      redirect '/control/login'
    end
  end
  
  def unset_current_user
    session[:user] = nil
    return true
  end
  
  def only_authorized
    raise AccessDenied unless @user
  end
  
  def only_superusers
    raise AccessDenied unless current_user.superuser
  end
  
  def only_can_read(bucket)
    raise AccessDenied unless bucket.readable_by? current_user
  end
  
  def only_can_write(bucket)
    raise AccessDenied unless bucket.writable_by? current_user
  end
  
  def only_owner_of(bucket)
    raise AccessDenied unless bucket.owned_by? current_user
  end
  
  def aws_only_owner_of(bucket)
    raise AccessDenied unless bucket.owned_by? @user
  end
  
  def aws_only_can_read(bucket)
    raise AccessDenied unless bucket.readable_by? @user
  end
  
  def check_credentials(username, password)
    user = User.first(:login => username)
    if user.password == hmac_sha1(password, user.s3secret)
      session[:user] = user
      return true
    else
      return false
    end
  end

  def get_prefix(c)
    c.file_name.sub(@input['prefix'], '').split(@input['delimiter'])[0] + @input['delimiter']
  end
  
  def current_user
    @user = User.first(:login => session[:user].login)
    return @user
  end
  
  def hmac_sha1(key, s)
    return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
  end
  
  def load_buckets
    buckets = current_user.buckets
    # Look up the buckets that the user has access to.
    @buckets = buckets
    @bucket = Bucket.new(:access => CANNED_ACLS['private'])
  end
end