class AccessDenied < StandardError; end
class AllAccessDisabled < StandardError; end
class AmbiguousGrantByEmailAddress < StandardError; end
class BadAuthentication < StandardError; end
class BadDigest < StandardError; end
class BucketAlreadyExists < StandardError; end
class BucketNotEmpty < StandardError; end
class CredentialsNotSupported < StandardError; end
class EntityTooLarge < StandardError; end
class IncompleteBody < StandardError; end
class InternalError < StandardError; end
class InvalidArgument < StandardError; end
class InvalidBucketName < StandardError; end
class InvalidDigest < StandardError; end
class InvalidRange < StandardError; end
class InvalidSecurity < StandardError; end
class InvalidSOAPRequest < StandardError; end
class InvalidStorageClass < StandardError; end
class InvalidURI < StandardError; end
class MalformedACLError < StandardError; end
class MethodNotAllowed < StandardError; end
class MissingContentLength < StandardError; end
class MissingSecurityElement < StandardError; end
class MissingSecurityHeader < StandardError; end
class NoSuchBucket < StandardError; end
class NoSuchKey < StandardError; end
class NotImplemented < StandardError; end
class NotModified < StandardError; end
class PreconditionFailed < StandardError; end
class RequestTimeout < StandardError; end
class RequestTorrentOfBucketError < StandardError; end
class TooManyBuckets < StandardError; end
class UnexpectedContent < StandardError; end
class UnresolvableGrantByEmailAddress < StandardError; end

error AccessDenied do
  throw :halt, [403, 'Access Denied.']
end

error AllAccessDisabled do
  throw :halt, [401, 'All access to this object has been disabled.']
end

error AmbiguousGrantByEmailAddress do
  throw :halt, [400, 'The e-mail address you provided is associated with more than one account.']
end

error BadAuthentication do
  throw :halt, [401, 'The authorization information you provided is invalid. Please try again.']
end

error BadDigest do
  throw :halt, [400, 'The Content-MD5 you specified did not match what we received.']
end

error BucketAlreadyExists do
  throw :halt, [409, 'The named bucket you tried to create already exists.']
end

error BucketNotEmpty do
  throw :halt, [409, 'The bucket you tried to delete is not empty.']
end

error CredentialsNotSupported do
  throw :halt, [400, 'This request does not support credentials.']
end

error EntityTooLarge do
  throw :halt, [400, 'Your proposed upload exceeds the maximum allowed object size.']
end

error IncompleteBody do
  throw :halt, [400, 'You did not provide the number of bytes specified by the Content-Length HTTP header.']
end

error InternalError do
  throw :halt, [500, 'We encountered an internal error. Please try again.']
end

error InvalidArgument do
  throw :halt, [400, 'Invalid Argument']
end

error InvalidBucketName do
  throw :halt, [400, 'The specified bucket is not valid.']
end

error InvalidDigest do
  throw :halt, [400, 'The Content-MD5 you specified was an invalid.']
end

error InvalidRange do
  throw :halt, [416, 'The requested range is not satisfiable.']
end

error InvalidSecurity do
  throw :halt, [403, 'The provided security credentials are not valid.']
end

error InvalidSOAPRequest do
  throw :halt, [400, 'The SOAP request body is invalid.']
end

error InvalidStorageClass do
  throw :halt, [400, 'The storage class you specified is not valid.']
end

error InvalidURI do
  throw :halt, [400, "Couldn't parse the specified URI."]
end

error MalformedACLError do
  throw :halt, [400, 'The XML you provided was not well-formed or did not validate against our published schema.']
end

error MethodNotAllowed do
  throw :halt, [405, 'The specified method is not allowed against this resource.']
end

error MissingContentLength do
  throw :halt, [411, 'You must provide the Content-Length HTTP header.']
end

error MissingSecurityElement do
  throw :halt, [400, 'The SOAP 1.1 request is missing a security element.']
end

error MissingSecurityHeader do
  throw :halt, [400, 'Your request was missing a required header.']
end

error NoSuchBucket do
  throw :halt, [404, 'The specified bucket does not exist.']
end

error NoSuchKey do
  throw :halt, [404, 'The specified key does not exist.']
end

error NotImplemented do
  throw :halt, [501, 'A header you provided implies functionality that is not implemented.']
end

error NotModified do
  throw :halt, [304, 'The request resource has not been modified.']
end

error PreconditionFailed do
  throw :halt, [412, 'At least one of the pre-conditions you specified did not hold.']
end

error RequestTimeout do
  throw :halt, [400, 'Your socket connection to the server was not read from or written to within the timeout period.']
end

error RequestTorrentOfBucketError do
  throw :halt, [400, 'Requesting the torrent file of a bucket is not permitted.']
end

error TooManyBuckets do
  throw :halt, [400, 'You have attempted to create more buckets than allowed.']
end

error UnexpectedContent do
  throw :halt, [400, 'This request does not support content.']
end

error UnresolvableGrantByEmailAddress do
  throw :halt, [400, 'The e-mail address you provided does not match any account on record.']
end