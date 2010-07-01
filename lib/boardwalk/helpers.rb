helpers do  
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
    raise AccessDenied unless current_user
  end
  
  def only_can_read(bucket)
    throw :halt, [403, "Access Denied"] unless bucket.readable_by? current_user
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
  
  def check_access user, group_perm, user_perm
      !!( if owned_by?(user) or (user and access & group_perm > 0) or (access & user_perm > 0)
              true
          elsif user
              acl = users.find(user.id) rescue nil
              acl and acl.access.to_i & user_perm
          end )
  end
  
  def owned_by? user
      user and owner_id == user.id
  end
  
  def readable_by? user
      check_access(user, READABLE_BY_AUTH, READABLE)
  end
  
  def writable_by? user
      check_access(user, WRITABLE_BY_AUTH, WRITABLE)
  end
end