current = File.join(File.dirname(__FILE__))
##
# This file will contain routes for the S3 REST API.
##

##
# class RService < S3 '/'
##
get '/' do
  puts "Root route."
  # @user is set here.
  aws_authenticate
  content_type "application/xml"
  # Make sure said user is able to access this.
  only_authorized
  # Basically find all the buckets associated with the user
  buckets = @user.buckets
  # Render XML that is used by the S3 API making call.
  # NOTE: This could be done in an external .builder file, however I'm not sure
  #       how well instance variables can be passed this way. But external 
  #       files might allow the routes themselves to load faster since there 
  #       will not be as much pollution in the file.
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
                  x.CreationDate b.created_at#.getgm.iso8601
              end
            end
          end
      end
    end
  end
end

##
# class RBucket < S3 '/([^\/]+)/?'
put %r{/([^\/]+)/?} do
  puts "Secondary route."
  aws_authenticate
  only_authorized
  bucket_name = params[:captures].first
  bucket = Bucket.first(:name => bucket_name)
  puts bucket.inspect
  amz = CANNED_ACLS[@amz]
  if bucket.nil?
    @user.buckets.create(:name => params[:captures].first, :access => amz)
    request.env['Location'] = request.env['PATH_INFO']
    request.env['Content-Length'] = 0
    status 200
  else
    throw :halt, [409, "The named bucket you tried to create already exists."]
  end
end

delete %r{/([^\/]+)/?} do
  aws_authenticate
  bucket = Bucket.all(:conditions => {:name => params[:captures].first}).first
  puts "Bucket inspect: "+bucket.inspect
  puts "Bucket class: "+bucket.class.to_s
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
=begin
  def get(bucket_name)
      bucket = Bucket.find_root(bucket_name)
      only_can_read bucket

      if @input.has_key? 'torrent'
          return torrent(bucket)
      end
      opts = {:conditions => ['parent_id = ?', bucket.id], :order => "name"}
      limit = nil
      if @input.prefix
          opts[:conditions].first << ' AND name LIKE ?'
          opts[:conditions] << "#{@input.prefix}%"
      end
      if @input.marker
          opts[:offset] = @input.marker.to_i
      end
      if @input['max-keys']
          opts[:limit] = @input['max-keys'].to_i
      end
      slot_count = Slot.count :conditions => opts[:conditions]
      contents = Slot.find :all, opts
    
      if @input.delimiter
        @input.prefix = '' if @input.prefix.nil?
      
        # Build a hash of { :prefix => content_key }. The prefix will not include the supplied @input.prefix.
        prefixes = contents.inject({}) do |hash, c|
          prefix = get_prefix(c).to_sym
          hash[prefix] = [] unless hash[prefix]
          hash[prefix] << c.name
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

      xml do |x|
          x.ListBucketResult :xmlns => "http://s3.amazonaws.com/doc/2006-03-01/" do
              x.Name bucket.name
              x.Prefix @input.prefix if @input.prefix
              x.Marker @input.marker if @input.marker
              x.Delimiter @input.delimiter if @input.delimiter
              x.MaxKeys @input['max-keys'] if @input['max-keys']
              x.IsTruncated slot_count > contents.length + opts[:offset].to_i
              contents.each do |c|
                  x.Contents do
                      x.Key c.name
                      x.LastModified c.updated_at.getgm.iso8601
                      x.ETag c.etag
                      x.Size c.obj.size
                      x.StorageClass "STANDARD"
                      x.Owner do
                          x.ID c.owner.key
                          x.DisplayName c.owner.login
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
=end
get %r{/([^\/]+)/?} do
  
end
# 
#     private
#     def get_prefix(c)
#       c.name.sub(@input.prefix, '').split(@input.delimiter)[0] + @input.delimiter
#     end
# end
##