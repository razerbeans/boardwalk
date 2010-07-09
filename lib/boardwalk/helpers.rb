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
    throw :halt, [403, "Access Denied."] unless current_user
  end
  
  def only_superusers
    throw :halt, [403, "Access Denied."] unless current_user.superuser
  end
  
  def only_can_read(bucket)
    # throw :halt, [403, "Access Denied"] unless bucket.readable_by? current_user
    throw :halt, [403, "Access Denied."] unless bucket.readable_by? current_user
  end
  
  def only_can_write(bucket)
    # throw :halt, [403, "Access Denied"] unless bucket.writable_by? current_user
    throw :halt, [403, "Access Denied."] unless bucket.writable_by? current_user
  end
  
  def only_owner_of(bucket)
    throw :halt, [403, "Access Denied."] unless bucket.owned_by? current_user
  end
  
  def check_credentials(username, password)
    user = User.first(:login => username)
    puts user.inspect
    puts "COMPARISON #{hmac_sha1(password, user.s3secret)}"
    if user.password == hmac_sha1(password, user.s3secret)
      session[:user] = user
      return true
    else
      return false
    end
  end
  
  def current_user
    return User.first(:login => session[:user].login)
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