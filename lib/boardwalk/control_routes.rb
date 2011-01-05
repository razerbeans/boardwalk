get '/control/?' do
  login_required
  redirect '/control/buckets'
end

get '/control/login/?' do
  @title = 'Login'
  haml :control_login
end

post '/control/login' do
  if check_credentials(params[:login], params[:password])
    redirect '/control/buckets'
  else
    @title = "Login"
    haml :control_login
  end
end

get '/control/logout' do
  login_required
  if unset_current_user
    redirect '/control'
  else
    "An error occured!"
  end
end

get '/control/buckets/?' do
  login_required
  load_buckets
  @plain = '<script type="text/javascript" src="/js/buckets.js"></script>'
  @title="Buckets"
  haml :control_buckets
end

post '/control/buckets' do
  unless current_user.buckets.find(:name => params[:bucket_name])
    bucket = current_user.buckets.build(:name => params[:bucket_name], :access => params[:bucket_access], :created_at => Time.now)
    unless bucket.save!
      throw :halt, [500, "Could not create new bucket."]
    end
  end
  load_buckets
  @plain = '<script type="text/javascript" src="/js/buckets.js"></script>'
  @title="Buckets"
  haml :control_buckets
end

# NOTE: This route MUST come before get %r{/control/buckets/([^\/]+)} or things
#       will break! -Randall
get %r{/control/buckets/([^\/]+?)/(.+)} do
  bucket = current_user.buckets.to_enum.find{|b| b.name == params[:captures][0]}
  slot = bucket.slots.to_enum.find{|s| s.file_name == params[:captures][1]}
  only_can_read slot
  
  since = Time.httpdate(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil
  if since && (slot.bit.upload_date) <= since
    raise NotModified
  end
  since = Time.httpdate(request.env['HTTP_IF_UNMODIFIED_SINCE']) rescue nil
  if (since && (slot.updated_at > since)) or (request.env['HTTP_IF_MATCH'] && (slot.md5 != request.env['HTTP_IF_MATCH']))
    raise PreconditionFailed
  end
  if request.env['HTTP_IF_NONE_MATCH'] && (slot.md5 == request.env['HTTP_IF_NONE_MATCH'])
    raise NotModified
  end
  if request.env['HTTP_RANGE']
    raise NotImplemented
  end
  tempf = Tempfile.new("#{slot.file_name}")
  tempf.puts slot.bit.data
  send_file(tempf.path, {:disposition => 'attachment', :filename => slot.file_name, :type => slot.bit_type, :length => slot.bit_size})
  tempf.close!
  status 200
end

get %r{/control/buckets/([^\/]+)} do
  login_required
  current_user.buckets.each do |b|
    if b.name == params[:captures].first
      @bucket = b
    end
  end
  @files = @bucket.slots
  @plain = '<script type="text/javascript" src="/js/files.js"></script>'
  haml :control_files
end

post %r{/control/buckets/([^\/]+)} do
  current_user.buckets.each do |b|
    if b.name == params[:captures].first
      @bucket = b
    end
  end
  only_can_write @bucket
  tempfile = params[:upfile][:tempfile]
  params[:fname] == '' ? filename = params[:upfile][:filename] : filename = params[:fname]
  slot = @bucket.slots.build(:bit => tempfile.open, :file_name => filename, :access => params[:facl], :created_at => Time.now, :updated_at => Time.now)
  unless slot.save!
    throw :halt, [500, "Could not upload file to bucket."]
  end
  redirect '/control/buckets/'+@bucket.name
end

post '/control/delete' do
  login_required
  if params[:deletion_type] == 'bucket'
    bucket = current_user.buckets.to_enum.find{|b| b.name == params[:bucket_name]}
    only_owner_of bucket
    if bucket.slots.empty?
      if bucket.delete
        current_user.buckets.delete_if{|b| b.name == bucket.name}
        status 200
      else
        throw :halt, [500, "Could not delete bucket (error)."]
      end
    else
      throw :halt, [500, "Bucket cannot be deleted since it's not empty."]
    end
  elsif params[:deletion_type] == 'file'
    bucket = current_user.buckets.to_enum.find{|b| b.name == params[:bucket_name]}
    only_can_write(bucket)
    slot = bucket.slots.to_enum.find{|s| s.file_name == params[:file_name]}
    if slot.delete
      bucket.slots.delete_if{|s| s.file_name == slot.file_name}
      status 200
    else
      throw :halt, [500, "Could not delete file (error)."]
    end
  end
end

get '/control/users' do
  login_required
  only_superusers
  @usero = User.new
  # Find all the users that aren't marked as deleted.
  @users = User.all(:conditions => {'deleted' => false}) # <conditions>
  @title = "User List"
  @plain = '<script type="text/javascript" src="/js/users.js"></script>'
  haml :control_users
end

post '/control/users' do
  login_required
  only_superusers
  superuser = false
  superuser = true if params[:superuser] == 'on'
  throw :halt, [500, "Passwords did not match!"] if params[:password] != params[:password_confirmation]
  @usero = User.create(:login => params[:login], :password => params[:password], :superuser => superuser, :email => params[:email], :s3key => params[:key], :s3secret => params[:secret], :created_at => Time.now)
  @usero.password = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), @usero.password, @usero.s3secret)).strip
  if @usero.valid?
    if @usero.save
      redirect '/control/users'
      status 200
    else
      throw :halt, [500, "Error processing user."]
    end
  else
    haml :control_user
  end
end

post %{/control/users/delete} do
  login_required
  only_superusers
  @usero = User.all(:conditions => {'login' => params[:login]}).first
  if @usero.login == current_user.login
    error "Suicide is not an option."
  else
    @usero.delete
  end
end

get %r{/control/users/([^\/]+)} do
  login_required
  only_superusers
  @usero = User.all(:conditions => {'login' => params[:captures].first}).first
  @title = @usero.login
  haml :control_profile
end

# Ugh. This is so brute-force and nasty. Need to clean this up later -Randall
# Also, there is a possibility that a user could send s3key and s3secret post
#   data to alter their information even though it shouldn't be allowed. Need
#   to adjust for this later. -Randall
post %r{/control/users/([^\/]+)} do
  login_required
  only_superusers
  throw :halt, [500, "Passwords did not match!"] if params[:password] != params[:password_confirmation]
  @usero =  User.all(:conditions => {'login' => params[:captures].first}).first
  posted_info = {}
  params.delete 'password_confirmation'
  params.each { |k,v| posted_info["#{k}"] = "#{v}" if v != '' && k != 'captures' }
  if params[:superuser] == 'on'
    posted_info.merge!({'superuser' => true})
  else
    posted_info.merge!({'superuser' => false})
  end
  posted_info[:password] = hmac_sha1(params[:password], @usero.s3secret) if posted_info.has_key? 'password'
  @usero.update_attributes(posted_info) rescue throw :halt, [500, "There was an error updating user record."]
  @title = @usero.login
  haml :control_profile
end

get '/control/profile' do
  @usero = current_user
  throw :halt, [500, "Passwords did not match!"] if params[:password] != params[:password_confirmation]
  @title = "Your Profile"
  haml :control_profile
end

post '/control/profile' do
  @usero = current_user
  posted_info = {}
  params.delete 'password_confirmation'
  params.each { |k,v| posted_info["#{k}"] = "#{v}" if v != '' && k != 'captures' }
  if params[:superuser] == 'on'
    posted_info.merge!({'superuser' => true})
  else
    posted_info.merge!({'superuser' => false})
  end
  posted_info[:password] = hmac_sha1(params[:password], @usero.s3secret) if posted_info.has_key? 'password'
  current_user.update_attributes(posted_info) rescue throw :halt, [500, "There was an error updating your records."]
  @usero = current_user
  @title = "Your Profile"
  haml :control_profile
end