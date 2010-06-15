# require 'mongo_mapper'
# require 'grip'

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
  
  property :login,         String,   :length => (3..40),  :required => true
  property :password,      String,   :length => 40,       :required => true
  property :email,         String,   :length => 64
  property :s3key,         String,   :length => 64,       :required => true
  property :s3secret,      String,   :length => 64,       :required => true
  property :created_at,    DateTime
  property :activated_at,  DateTime
  property :superuser,     Integer,  :default => 0
  property :deleted,       Boolean,  :default => false
  
  validates_is_unique :login
  validates_is_unique :key
  
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
  
  property :lft,         Integer
  property :rgt,         Integer
  property :type,        String,   :length => 6
  property :name,        String,   :length => 255
  property :created_at,  DateTime
  property :updated_at,  DateTime
  property :access,      Integer
  property :meta,        Text
  
  belongs_to :user
  has n, :bits
end

class Bit
  include DataMapper::Resource
  
  property :type,        String, :length => 6
  property :name,        String, :length => 255
  property :created_at,  Time
  property :updated_at,  Time
  
  belongs_to :bucket
  # has n, :objs
end