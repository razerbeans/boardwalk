current = File.join(File.dirname(__FILE__))

class FakeBucket
  def initialize
    @name = rand(999) + 1
    @created_at = Time.local(2000,1,1,20,15,1)
  end
  
  def name
    @name
  end
  
  def created_at
    @created_at
  end
end

##
# This file will contain routes for the S3 REST API.
##

##
# class RService < S3 '/'
#     def get
#         only_authorized
#         buckets = Bucket.find :all, :conditions => ['parent_id IS NULL AND owner_id = ?', @user.id], :order => "name"
# 
#         xml do |x|
#             x.ListAllMyBucketsResult :xmlns => "http://s3.amazonaws.com/doc/2006-03-01/" do
#                 x.Owner do
#                     x.ID @user.key
#                     x.DisplayName @user.login
#                 end
#                 x.Buckets do
#                     buckets.each do |b|
#                         x.Bucket do
#                             x.Name b.name
#                             x.CreationDate b.created_at.getgm.iso8601
#                         end
#                     end
#                 end
#             end
#         end
#     end
# end
##
get '/' do
  aws_authenticate
  content_type "application/xml"
  # I'm assuming this checks the keys that the user is using for the API call.
  # Question: How do we set the user istance variable for this? Passthrough 
  #           the only_authorized method?
  only_authorized
  # Basically find all the buckets associated with the user
  # buckets = []
  # seed = rand(9) + 1
  # seed.times do 
  #   buckets << FakeBucket.new # Bucket.find(:all)
  # end
  buckets = @user.buckets
  # Render XML that is used by the S3 API making call.
  # NOTE: This could be done in an external .builder file, however I'm not sure
  #       how well instance variables can be passed this way. But external 
  #       files may allow the routes themselves to load faster since there 
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
              x.Bucket do
                  x.Name b.name
                  x.CreationDate b.created_at#.getgm.iso8601
              end
          end
      end
    end
  end
end

##
# class RBucket < S3 '/([^\/]+)/?'
#     def put(bucket_name)
#         only_authorized
#         bucket = Bucket.find_root(bucket_name)
#         only_owner_of bucket
#         bucket.grant(requested_acl)
#         raise BucketAlreadyExists
#     rescue NoSuchBucket
#         Bucket.create(:name => bucket_name, :owner_id => @user.id).grant(requested_acl)
#         r(200, '', 'Location' => @env.PATH_INFO, 'Content-Length' => 0)
#     end
put %r{/([^\/]+)/?} do
  aws_authenticate
  only_authorized
  bucket_name = params[:capture]#.first
  bucket = Bucket.find_root(bucket_name)
  if !bucket
    @user.buckets.create(:name => params[:capture], :owner_id => @user.id)
  end
  # only_owner_of(bucket)
end
#     def delete(bucket_name)
#         bucket = Bucket.find_root(bucket_name)
#         only_owner_of bucket
# 
#         if Slot.count(:conditions => ['parent_id = ?', bucket.id]) > 0
#             raise BucketNotEmpty
#         end
#         bucket.destroy
#         r(204, '')
#     end
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