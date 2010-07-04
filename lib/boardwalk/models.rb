MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = 'boardwalk_development'

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
  validates_uniqueness_of :s3key
  
  many :buckets
  
  # before_save :convert_pass
  # after_save :revert_pass
  private
    def hmac_sha1(key, s)
      return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
    end
    def convert_pass
        @password_clean = self.password
        self.password = hmac_sha1(self.password, self.s3secret)
    end
    def revert_pass
        self.password = @password_clean
    end
end

class Bucket
  include MongoMapper::EmbeddedDocument
  
  key :user_id,     String
  key :type,        String,   :length => 6
  key :name,        String,   :length => 255, :format => /^[-\w]+$/
  key :created_at,  Time
  key :updated_at,  Time
  key :access,      Integer
  key :meta,        String
  
  validates_uniqueness_of :name
  
  belongs_to :user
  many :slots
    
  def access_readable
      name, _ = CANNED_ACLS.find { |k, v| v == self.access }
      if name
          name
      else
          [0100, 0010, 0001].map do |i|
              [[4, 'r'], [2, 'w'], [1, 'x']].map do |k, v|
                  (self.access & (i * k) == 0 ? '-' : v )
              end
          end.join
      end
  end
  def self.readable_by? bucket
      check_access(bucket.user, READABLE_BY_AUTH, READABLE)
  end
  def owned_by? current_user
      current_user and user.login == current_user.login
  end
  def writable_by? current_user
      check_access(current_user, WRITABLE_BY_AUTH, WRITABLE)
  end
  # private
  def check_access user, group_perm, user_perm
      !!( if owned_by?(user) or (user and (access > 0 && group_perm > 0)) or (access > 0 && user_perm > 0)
              true
          elsif user
              acl = users.find(user.id) rescue nil
              acl and acl.access.to_i & user_perm
          end )
  end
end

class Slot
  include MongoMapper::EmbeddedDocument
  plugin Joint
  
  attachment :file
  
  key :access,      Integer
  key :updated_at,  Time
  key :created_at,  Time
  key :md5,         String
  
  belongs_to :bucket
  
  def access_readable
      name, _ = CANNED_ACLS.find { |k, v| v == self.access }
      if name
          name
      else
          [0100, 0010, 0001].map do |i|
              [[4, 'r'], [2, 'w'], [1, 'x']].map do |k, v|
                  (self.access & (i * k) == 0 ? '-' : v )
              end
          end.join
      end
  end
end

user = User.create({
                    :login => "admin",
                    :password => "pass@word1",
                    :email => "admin@boardwalk",
                    :s3key => "44CF9590006BF252F707",
                    :s3secret => "OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV",
                    :created_at => Time.now,
                    :activated_at => Time.now,
                    :superuser => 1
                  })
user.password = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), user.password, user.s3secret)).strip
user.buckets << Bucket.new(:name => "_adminbucket", :access => 384)
user.save