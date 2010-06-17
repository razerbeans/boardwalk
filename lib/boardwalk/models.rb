# require 'mongo_mapper'
# require 'grip'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'mysql://root:into3ternity@localhost/boardwalk_development')
# class User
#   include MongoMapper::Document
#   
#   key :login,         String,   :length => (3..40), :required => true
#   key :password,      String,   :limit => 40,       :required => true
#   key :email,         String,   :limit => 64
#   key :s3key,         String,   :limit => 64,       :required => true
#   key :s3secret,      String,   :limit => 64,       :required => true
#   key :created_at,    Time
#   key :activated_at,  Time
#   key :superuser,     Integer,  :default => 0
#   key :deleted,       Boolean,  :default => false
#   
#   validates_uniqueness_of :login
#   validates_uniqueness_of :key
#   
#   many :buckets
#   
#   def authenticate(login, password)
#     user = User.get(:login => login)
#     if user.password == hmac_sha1(password, user.secret)
#       return user
#     else
#       return nil
#     end
#   end
# end

class User
  include DataMapper::Resource

  property :id,           Serial
  property :login,        String,   :length => (3..40),  :required => true
  property :password,     String,   :length => 40,       :required => true
  property :email,        String,   :length => 64
  property :s3key,        String,   :length => 64,       :required => true
  property :s3secret,     String,   :length => 64,       :required => true
  property :created_at,   DateTime
  property :activated_at, DateTime
  property :superuser,    Integer,  :default => 0
  property :deleted,      Boolean,  :default => false
  
  validates_is_unique :login
  validates_is_unique :s3key
  
  has n, :buckets
    
  def authenticate(login, password)
    user = User.get(:login => login)
    if user.password == hmac_sha1(password, user.secret)
      return user
    else
      return nil
    end
  end
end

class Bucket
  include DataMapper::Resource
  
  property :id,         Serial
  property :lft,        Integer
  property :rgt,        Integer
  property :type,       String,   :length => 6
  property :name,       String,   :length => 255, :format => /^[-\w]+$/
  property :created_at, DateTime
  property :updated_at, DateTime
  property :access,     Integer
  property :meta,       Text
  property :parent_id,  Integer
  property :owner_id,   Integer
  
  belongs_to :user
  has n, :bits
  
  def self.find_root(bucket_name)
    first(:parent_id => '', :name => bucket_name)
  end
end

class Bit
  include DataMapper::Resource
  
  property :id,         Serial
  property :type,       String, :length => 6
  property :name,       String, :length => 255
  property :created_at, Time
  property :updated_at, Time
  
  belongs_to :bucket
  # has n, :objs
end

DataMapper.auto_migrate!
# DataMapper.auto_upgrade!
user = User.new(:login => "admin", :password => "pass@word1", :s3key => "44CF9590006BF252F707", :s3secret => "OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV", :superuser => 1)
user.buckets.new(:name => "_adminbucket")
user.save