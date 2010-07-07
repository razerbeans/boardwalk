##
# This file will contain the routes for the web-based administration 
# and control.
##

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
  puts @buckets.inspect
  # When _why uses :control, he uses it as a "universal" layout. :buckets 
  # specifies the content yielded in this "universal" layout.
  @title="Buckets"
  haml :control_buckets
end

post '/control/buckets' do
  unless current_user.buckets.find(:name => params[:bucket_name])
    bucket = current_user.buckets.build(:name => params[:bucket_name], :access => params[:bucket_access])
    unless bucket.save!
      throw :halt, [500, "Could not create new bucket."]
    end
  end
  load_buckets
  @title="Buckets"
  haml :control_buckets
end

##
# class CFile < R '/control/buckets/([^\/]+?)/(.+)'
#     login_required
#     include ParkPlace::SlotGet
#     ##
#     # Here's a dump of ParkPlace::SlotGet
#     #
#     # module SlotGet
#     #   def head(bucket_name, oid)
#     #       @slot = ParkPlace::Models::Bucket.find_root(bucket_name).find_slot(oid)
#     #       only_can_read @slot
#     #   
#     #       etag = @slot.etag
#     #       since = Time.httpdate(@env.HTTP_IF_MODIFIED_SINCE) rescue nil
#     #       raise NotModified if since and @slot.updated_at <= since
#     #       since = Time.httpdate(@env.HTTP_IF_UNMODIFIED_SINCE) rescue nil
#     #       raise PreconditionFailed if since and @slot.updated_at > since
#     #       raise PreconditionFailed if @env.HTTP_IF_MATCH and etag != @env.HTTP_IF_MATCH
#     #       raise NotModified if @env.HTTP_IF_NONE_MATCH and etag == @env.HTTP_IF_NONE_MATCH
#     #   
#     #       headers = {}
#     #       if @slot.meta
#     #           @slot.meta.each { |k, v| headers["x-amz-meta-#{k}"] = v }
#     #       end
#     #       if @slot.obj.is_a? ParkPlace::Models::FileInfo
#     #           headers['Content-Type'] = @slot.obj.mime_type
#     #           headers['Content-Disposition'] = @slot.obj.disposition
#     #       end
#     #       headers['Content-Type'] ||= 'binary/octet-stream'
#     #       r(200, '', headers.merge('ETag' => etag, 'Last-Modified' => @slot.updated_at.httpdate, 'Content-Length' => @slot.obj.size))
#     #   end
#     #   def get(bucket_name, oid)
#     #       head(bucket_name, oid)
#     #       if @input.has_key? 'torrent'
#     #           torrent @slot
#     #       elsif @env.HTTP_RANGE  # ugh, parse ranges
#     #           raise NotImplemented
#     #       else
#     #           case @slot.obj
#     #           when ParkPlace::Models::FileInfo
#     #               file_path = File.join(STORAGE_PATH, @slot.obj.path)
#     #               headers['X-Sendfile'] = file_path
#     #           else
#     #               @slot.obj
#     #           end
#     #       end
#     #   end
get %r{/control/buckets/([^\/]+?)/(.+)} do
  bucket = current_user.buckets.to_enum.find{|b| b.name == params[:captures][0]}
  slot = bucket.slots.to_enum.find{|s| s.file_name == params[:captures][1]}
  only_can_read slot
  
  since = Time.httpdate(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil
  if since && (slot.bit.upload_date) <= since
    throw :halt, [304, "The request resource has not been modified."]
  end
  since = Time.httpdate(request.env['HTTP_IF_UNMODIFIED_SINCE']) rescue nil
  if (since && (slot.updated_at > since)) or (request.env['HTTP_IF_MATCH'] && (slot.md5 != request.env['HTTP_IF_MATCH']))
    throw :halt, [412, "At least one of the pre-conditions you specified did not hold."]
  end
  if request.env['HTTP_IF_NONE_MATCH'] && (slot.md5 == request.env['HTTP_IF_NONE_MATCH'])
    throw :halt, [304, "The request resource has not been modified."]
  end
  # headers['Content-Type'] = slot.bit_type || "binary/octet-stream"
  if request.env['HTTP_RANGE']
    throw :halt, [501, "A header you provided implies functionality that is not implemented."]
  end
  # headers['ETag'] = slot.file.server_md5
  # headers['Last-Modified'] = slot.updated_at.httpdate
  # headers['Content-Length'] = slot.bit_size.to_s
  # headers['Content-Disposition'] = "attachment; filename=\"#{slot.file_name}\""
  tempf = Tempfile.new("#{slot.file_name}")
  tempf.puts slot.bit.data
  puts "* Slot inspection: " + slot.inspect + " *"
  puts "\t*** " + slot.class.to_s + " ***"
  puts "* File inspection: " + slot.bit.inspect + " *"
  puts "\t*** " + slot.bit.class.to_s + " ***"
  puts "* Grid inspection: " + slot.bit.grid_io.inspect + " *"
  puts tempf.path
  # puts slot.bit.grid_io.methods
  send_file(tempf.path, {:disposition => 'attachment', :filename => slot.file_name, :type => slot.bit_type})
  tempf.close!
  status 200
end
# OR
# get %r{/control/buckets/([^\/]+?)/(.+)} do |bucket_name, oid|
#   # May eliminate need for params[:captures].first, etc.
#   head(bucket_name, oid)
#end
#     #
#     #
#     # end
# end
##

get %r{/control/buckets/([^\/]+)} do
  login_required
  # Pull the bucket from the route.
  # Find the root of the requested bucket and set as an instance variable.
  # @bucket = current_user.buckets.find(:name => "#{params[:captures].first}")
  puts "AHHHH!"
  current_user.buckets.each do |b|
    if b.name == params[:captures].first
      @bucket = b
    end
  end
  # I'm assuming only_can_read is checking read permissions on the bucket.
  # only_can_read @bucket
  # Pull all the files in the bucket. Probably will ignore torrenting.
  @files = @bucket.slots
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
  slot = @bucket.slots.build(:bit => tempfile.open, :file_name => filename, :access => params[:facl])
  unless slot.save!
    throw :halt, [500, "Could not upload file to bucket."]
  end
  redirect '/control/buckets/'+@bucket.name
end

=begin
##
# class CDeleteBucket < R '/control/delete/([^\/]+)'
#     login_required
#     def post(bucket_name)
#         bucket = Bucket.find_root(bucket_name)
#         only_owner_of bucket
# 
#         if Slot.count(:conditions => ['parent_id = ?', bucket.id]) > 0
#             error "Bucket #{bucket.name} cannot be deleted, since it is not empty."
#         else
#             bucket.destroy
#         end
#         redirect CBuckets
#     end
# end
##
post %r{/control/delete/([^\/]+)} do
  login_required
  bucket = Bucket.find(params[:capture].first)
  only_owner_of(bucket)
  # IF bucket_has_slots
  #   ERROR "Bucket not empty!"
  # ELSE
  #   bucket.destroy!
  # END
  redirect '/control/buckets'
end

##
# class CDeleteFile < R '/control/delete/(.+?)/(.+)'
#     login_required
#     def post(bucket_name, oid)
#         bucket = Bucket.find_root bucket_name
#         only_can_write bucket
#         slot = bucket.find_slot(oid)
#         slot.destroy
#         redirect CFiles, bucket_name
#     end
# end
##
post %r{/control/delete/(.+?)/(.+)} do
  login_required
  bucket = Bucket.find(params[:capture].first)
  only_can_write(bucket)
  slot = bucket.find_slot(params[:capture].second)
  slot.destroy!
  redirect "/control/buckets/#{params[:capture].first}"
end

##
# class CUsers < R '/control/users'
#     login_required
#     def get
#         only_superusers
#         @usero = User.new
#         @users = User.find :all, :conditions => ['deleted != 1'], :order => 'login'
#         render :control, "User List", :users
#     end
get '/control/users' do
  login_required
  superuser_required
  # Don't understand the need for this. I assume it's for a new user form in
  # the view.
  @usero = User.new
  # Find all the users that aren't marked as deleted.
  @users = User.find :all # <conditions>
  haml :control_users
end
#     def post
#         only_superusers
#         @usero = User.new @input.user.merge(:activated_at => Time.now)
#         if @usero.valid?
#             @usero.save
#             redirect CUsers
#         else
#             render :control, "New User", :user
#         end
#     end
post '/control/users' do
  login_required
  superuser_required
  @usero = User.new # The stuff up top is to put the activation time in the 
                    # form (I think).
  if @usero.valid?
    @usero.save
    redirect '/control/users'
  else
    haml :control_user
  end
end
# end
##

##
# class CDeleteUser < R '/control/users/delete/(.+)'
#     login_required
#     def post(login)
#         only_superusers
#         @usero = User.find_by_login login
#         if @usero.id == @user.id
#             error "Suicide is not an option."
#         else
#             @usero.destroy
#         end
#         redirect CUsers
#     end
# end
##
post %{/control/users/delete/(.+)} do
  login_required
  superuser_required
  @usero = User.find_by_login(params[:capture].first)
  if @usero.id == @user.id
    error "Suicide is not an option."
  else
    @usero.destroy!
  end
  redirect '/control/users'
end

##
# class CUser < R '/control/users/([^\/]+)'
#     login_required
#     def get(login)
#         only_superusers
#         @usero = User.find_by_login login
#         render :control, "#{@usero.login}", :profile
#     end
get %r{/control/users/([^\/]+)} do
  login_required
  superuser_required
  @usero = User.find_by_login(params[:capture].first)
  haml :control_profile
end
#     def post(login)
#         only_superusers
#         @usero = User.find_by_login login
#         @usero.update_attributes(@input.user)
#         render :control, "#{@usero.login}", :profile
#     end
post %r{/control/users/([^\/]+)} do
  login_required
  superuser_required
  @usero = User.find_by_login(params[:capture].first)
  # params[:user] is from the user form.
  @user.update_attributes(params[:user])
  haml :control_profile
end
# end
##

# NOTE: These are Mongrel specific and I have no idea what they do. I'll just 
# have to incorperate it all later.
##
# class CProgressIndex < R '/control/progress'
#     def get
#         Mongrel::Uploads.instance.instance_variable_get("@counters").inspect
#     end
# end
##
get '/control/progress' do
  # Mongrel::Uploads.instance.instance_variable_get("@counters").inspect
end

##
# class CProgress < R '/control/progress/(.+)'
#     def get(upid)
#         Mongrel::Uploads.instance.check(upid).inspect
#     end
# end
##
get %r{/control/progress/(.+)} do
  # Mongrel::Uploads.instance.check(params[:capture].first).inspect
end

##
# class CProfile < R '/control/profile'
#     login_required
#     def get
#         @usero = @user
#         render :control, "Your Profile", :profile
#     end
get '/control/profile' do
  @usero = @user
  haml :control_profile
end
#     def post
#         @user.update_attributes(@input.user)
#         @usero = @user
#         render :control, "Your Profile", :profile
#     end
post '/control/profile' do
  @user.update_attributes(params[:user])
  @usero = @user
  haml :control_profile
end
# end
##

##
# class CStatic < R '/control/s/(.+)'
#     def get(path)
#         @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
#         @headers['X-Sendfile'] = File.join(ParkPlace::STATIC_PATH, path)
#     end
# end
##
get %r{/control/s/(.+)} do
  # Not entirely sure what all is needed here. Most likely other ways to do it
  # with rack.
end
=end