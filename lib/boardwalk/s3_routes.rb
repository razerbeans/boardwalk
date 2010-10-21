current = File.join(File.dirname(__FILE__))

get '/' do
  # @user is set here.
  aws_authenticate
  content_type "application/xml"
  only_authorized
  buckets = @user.buckets
  builder do |x|
    x.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    x.ListAllMyBucketsResult :xmlns => "http://s3.amazonaws.com/doc/2006-03-01/" do
      x.Owner do
          x.ID @user.s3key
          x.DisplayName @user.login
      end
      x.Buckets do
          buckets.each do |b|
            unless b.destroyed?
              x.Bucket do
                  x.Name b.name
                  x.CreationDate b.created_at.strftime("%Y-%m-%dT%H:%M:%S.000%Z") # Must match Amazon API Format (i.e. "2006-02-03T16:45:09.000Z")
              end
            end
          end
      end
    end
  end
end

put %r{/([^\/]+)/?} do
  aws_authenticate
  only_authorized
  bucket_name = params[:captures].first
  bucket = Bucket.first(:name => bucket_name)
  amz = CANNED_ACLS[@amz]
  if bucket.nil?
    @user.buckets.create(:name => params[:captures].first, :access => amz)
    request.env['Location'] = request.env['PATH_INFO']
    request.env['Content-Length'] = 0
    status 200
  else
    raise BucketAlreadyExists
  end
end

delete %r{/([^\/]+)/?} do
  aws_authenticate
  bucket = Bucket.all(:conditions => {:name => params[:captures].first}).first
  aws_only_owner_of bucket
  if bucket.slots.size > 0
    throw :halt, [409, "The bucket you tried to delete is not empty."]
  end
  if bucket.nil?
    throw :halt, [404, "The specified bucket does not exist."]
  end
  if Bucket.destroy(bucket.id)
    status 204
  else
    status 500
  end
end

get %r{/([^\/]+?)/(.+)} do 
  aws_authenticate
  bucket = @user.buckets.to_enum.find{|b| b.name == params[:captures][0]}
  slot = bucket.slots.to_enum.find{|s| s.file_name == params[:captures][1]}
  aws_only_can_read slot
  
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
  send_file(tempf.path, {:disposition => 'attachment', :filename => slot.file_name, :type => slot.bit_type})
  tempf.close!
  status 200
end

get %r{/([^\/]+)/?} do |e|
  aws_authenticate
  @input = request.params
  bucket = Bucket.all(:conditions => {:name => params[:captures].first}).first
  aws_only_can_read bucket

  if @input.has_key? 'torrent'
      raise NotImplemented
  end
  opts = {:conditions => {}, :order => "name"}
  limit = nil
  if @input['prefix']
    opts[:conditions] = opts[:conditions].merge({:file_name => /#{@input['prefix']}.*/i})
  end
  if @input['marker']
    opts[:offset] = @input['marker'].to_i
  end
  if @input['max-keys']
    opts[:limit] = @input['max-keys'].to_i
  end
  slot_count = Slot.all(:conditions => opts[:conditions]).size
  contents = Slot.all(opts)
  
  if @input['delimiter']
    @input['prefix'] = '' if @input['prefix'].nil?
  
    # Build a hash of { :prefix => content_key }. The prefix will not include the supplied @input.prefix.
    prefixes = contents.inject({}) do |hash, c|
      puts "C: " + c.inspect
      prefix = get_prefix(c).to_sym
      hash[prefix] = [] unless hash[prefix]
      hash[prefix] << c.file_name
      hash
    end
  
    # The common prefixes are those with more than one element
    common_prefixes = prefixes.inject([]) do |array, prefix|
      array << prefix[0].to_s if prefix[1].size > 1
      array
    end
  
    # The contents are everything that doesn't have a common prefix
    contents = contents.reject do |c|
      common_prefixes.include? get_prefix(c)
    end
  end
  
  builder do |x|
      x.ListBucketResult :xmlns => "http://s3.amazonaws.com/doc/2006-03-01/" do
          x.Name bucket.name
          x.Prefix @input['prefix'] if @input['prefix']
          x.Marker @input['marker'] if @input['marker']
          x.Delimiter @input['delimiter'] if @input['delimiter']
          x.MaxKeys @input['max-keys'] if @input['max-keys']
          x.IsTruncated slot_count > contents.length + opts['offset'].to_i
          contents.each do |c|
              x.Contents do
                  x.Key c.file_name
                  x.LastModified c.bit.upload_date.strftime("%Y-%m-%dT%H:%M:%S.000%Z")
                  x.ETag c.bit.grid_io.server_md5
                  x.Size c.bit.grid_io.file_length.to_i
                  x.StorageClass "STANDARD"
                  x.Owner do
                      x.ID c.bucket.user.s3key
                      x.DisplayName c.bucket.user.login
                  end
              end
          end
          if common_prefixes
            common_prefixes.each do |p|
              x.CommonPrefixes do
                x.Prefix p
              end
            end
          end
      end
  end
end