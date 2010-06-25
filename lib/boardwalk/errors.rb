# All errors are derived from ServiceError.  It's never actually raised itself, though.
class ServiceError < Exception; end

# A factory for building exception classes.
errors = YAML::load(<<-END)
    AccessDenied: [403, Access Denied]
    AllAccessDisabled: [401, All access to this object has been disabled.]
    AmbiguousGrantByEmailAddress: [400, The e-mail address you provided is associated with more than one account.]
    BadAuthentication: [401, The authorization information you provided is invalid. Please try again.]
    BadDigest: [400, The Content-MD5 you specified did not match what we received.]
    BucketAlreadyExists: [409, The named bucket you tried to create already exists.]
    BucketNotEmpty: [409, The bucket you tried to delete is not empty.]
    CredentialsNotSupported: [400, This request does not support credentials.]
    EntityTooLarge: [400, Your proposed upload exceeds the maximum allowed object size.]
    IncompleteBody: [400, You did not provide the number of bytes specified by the Content-Length HTTP header.]
    InternalError: [500, We encountered an internal error. Please try again.]
    InvalidArgument: [400, Invalid Argument]
    InvalidBucketName: [400, The specified bucket is not valid.]
    InvalidDigest: [400, The Content-MD5 you specified was an invalid.]
    InvalidRange: [416, The requested range is not satisfiable.]
    InvalidSecurity: [403, The provided security credentials are not valid.]
    InvalidSOAPRequest: [400, The SOAP request body is invalid.]
    InvalidStorageClass: [400, The storage class you specified is not valid.]
    InvalidURI: [400, Couldn't parse the specified URI.]
    MalformedACLError: [400, The XML you provided was not well-formed or did not validate against our published schema.]
    MethodNotAllowed: [405, The specified method is not allowed against this resource.]
    MissingContentLength: [411, You must provide the Content-Length HTTP header.]
    MissingSecurityElement: [400, The SOAP 1.1 request is missing a security element.]
    MissingSecurityHeader: [400, Your request was missing a required header.]
    NoSuchBucket: [404, The specified bucket does not exist.]
    NoSuchKey: [404, The specified key does not exist.]
    NotImplemented: [501, A header you provided implies functionality that is not implemented.]
    NotModified: [304, The request resource has not been modified.]
    PreconditionFailed: [412, At least one of the pre-conditions you specified did not hold.]
    RequestTimeout: [400, Your socket connection to the server was not read from or written to within the timeout period.]
    RequestTorrentOfBucketError: [400, Requesting the torrent file of a bucket is not permitted.]
    TooManyBuckets: [400, You have attempted to create more buckets than allowed.]
    UnexpectedContent: [400, This request does not support content.]
    UnresolvableGrantByEmailAddress: [400, The e-mail address you provided does not match any account on record.]
END

errors.each do |code, (status, msg)|
  ServiceError.const_set(code, Class.new(ServiceError) { 
      {:code=>code, :status=>status, :message=>msg}.each do |k,v|
          define_method(k) { v }
      end
  })
end