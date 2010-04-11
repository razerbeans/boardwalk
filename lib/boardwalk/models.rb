require 'mongo_mapper'
require 'grip'

class User
  include MongoMapper::Document
  
  key :login,         String,   :length => (3..40), :required => true
  key :password,      String,   :limit => 40,       :required => true
  key :email,         String,   :limit => 64
  key :s3key,         String,   :limit => 64,       :required => true
  key :s3secret,      String,   :limit => 64,       :required => true
  key :created_at,    Time
  key :activated_at,  Time
  key :superuser,     Integer,  :default => 0
  key :deleted,       Boolean,  :default => false
  
  validates_uniqueness_of :login
  validates_uniqueness_of :key
  
  many :buckets
  
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
  include MongoMapper::EmbeddedDocument
  
  key :lft,         :integer
  key :rgt,         :integer
  key :type,        :string,   :limit => 6
  key :name,        :string,   :limit => 255
  key :created_at,  :timestamp
  key :updated_at,  :timestamp
  key :access,      :integer
  key :meta,        :text
  
  many :bits
end

class Bit
  include MongoMapper::EmbeddedDocument
  include Grip::HasAttachment
  
  key :type,        String, :limit => 6
  key :name,        String, :limit => 255
  key :created_at,  Time
  key :updated_at,  Time
  
  has_grid_attachment :obj
end