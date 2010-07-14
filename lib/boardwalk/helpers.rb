helpers do
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
    c.name.sub(@input['prefix'], '').split(@input['delimiter'])[0] + @input['delimiter']
  end
  
  def current_user
    @user = User.first(:login => session[:user].login)
    return @user
  end
  
  def hmac_sha1(key, s)
    return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
  end
  
  def load_buckets
    # First, look up the buckets that are owned by the user.
    buckets = current_user.buckets
    # Second, look up the buckets that the user has access to.
    
    @buckets = buckets
    @bucket = Bucket.new(:access => CANNED_ACLS['private'])
  end
end