require 'mongo_mapper'
require 'grip'

MongoMapper.database = 'dev_boardwalk'

class User
  include MongoMapper::Document
  
  key :login,         String,   :limit => 40
  key :password,      String,   :limit => 40
  key :email,         String,   :limit => 64
  key :s3key,         String,   :limit => 64
  key :s3secret,      String,   :limit => 64
  key :created_at,    Time
  key :activated_at,  Time
  key :superuser,     Integer,  :default => 0
  key :deleted,       Boolean,  :default => false
  
  many :buckets
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