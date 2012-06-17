//
//  TCMyGengoAPIHandler.m
//  
//
//  Created by Christopher Trott on 6/14/12.
//  Copyright (c) 2012 TwoCentStudios. All rights reserved.
//

#import "TCMyGengoAPIHandler.h"


@implementation TCMyGengoAPICredentials

@synthesize isSandboxed = _isSandboxed;
@synthesize publicKey = _publicKey;
@synthesize privateKey = _privateKey;

+ (TCMyGengoAPICredentials *)sharedCredentials
{
  static TCMyGengoAPICredentials *sharedCredentials;
  
  @synchronized(self)
  {
    if (!sharedCredentials)
      sharedCredentials = [[TCMyGengoAPICredentials alloc] init];
    
    return sharedCredentials;
  }
}

- (void)setCredentialsWithPublicKey:(NSString *)publicKey
                         privateKey:(NSString *)privateKey
                        isSandboxed:(BOOL)isSandboxed{
  @synchronized(self) {
    [_publicKey release];
    _publicKey = [publicKey copy];
    
    [_privateKey release];
    _privateKey = [privateKey copy];
    
    _isSandboxed = isSandboxed;
  }
}

@end

@implementation TCMyGengoAPIHandler

@synthesize credentials = _credentials;

#pragma mark NSObject

- (id)initWithDelegate:(id<TCMyGengoAPIHandlerDelegate>)delegate 
           Credentials:(TCMyGengoAPICredentials *)credentials{
  if ((self = [super init])){
    _delegate = delegate;
    _credentials = credentials;
  }
  
  return self;
}

- (id)initWithDelegate:(id<TCMyGengoAPIHandlerDelegate>)delegate{
  return [self initWithDelegate:delegate 
                    Credentials:[TCMyGengoAPICredentials sharedCredentials]];
}

- (void)dealloc{
  _delegate = nil;
  [_httpRequest clearDelegatesAndCancel]; 
  [_httpRequest release]; _httpRequest = nil;
  [super dealloc];
}


#pragma mark Private

- (NSString *)formattedTimestamp{
  // We're using the Unix timestamp as the data. Not sure if this is right...
  return [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
}

- (NSString*) apiSignatureWithTimestamp:(NSString*)timestamp{  
  NSString *key = _credentials.privateKey;
    
  const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
  const char *cData = [timestamp cStringUsingEncoding:NSASCIIStringEncoding];

  unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

  CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
  
  NSMutableString* HMAC = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  
  for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    [HMAC appendFormat:@"%02x", cHMAC[i]];

  return HMAC;
}

- (void)getFromMyGengoEndPoint:(NSString*)endpoint 
                              withParams:(NSDictionary*)params
                                isDelete:(BOOL)isDelete{
  
  // Set up a completed url string that we'll append parameters to
  NSMutableString *CompleteURL = [NSMutableString stringWithString:@"http://"];
  
  // Add host (sandbox or production)
  [CompleteURL appendString:self.apiHost];
  
  // Add API version
  [CompleteURL appendFormat:@"/v%@/", self.apiVersion];
  
  // Add endpoint
  [CompleteURL appendString:endpoint];
    
  // Add API sig, API key, & timestamp to the params dictionary
  NSMutableDictionary *DictionaryParams = [NSMutableDictionary dictionaryWithDictionary:params];
  NSString *Timestamp = [self formattedTimestamp];
  [DictionaryParams setObject:Timestamp forKey:@"ts"];
  [DictionaryParams setObject:[self apiSignatureWithTimestamp:Timestamp] forKey:@"api_sig"];
  [DictionaryParams setObject:_credentials.publicKey forKey:@"api_key"];
  
  // Add all params to the post body
  // Per the myGengo API, these params must be sorted alphabetically by key
  NSMutableString *StringParams = nil;
  NSArray *SortedKeys = [[DictionaryParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
  for (NSString* Key in SortedKeys){
    if (StringParams == nil) {
      StringParams = [NSMutableString stringWithFormat:@"?%@=%@", Key, [DictionaryParams objectForKey:Key]];
    }else{
      [StringParams appendFormat:@"&%@=%@", Key, [DictionaryParams objectForKey:Key]];
    }
  }
  
  // Add param string to complete url
  [CompleteURL appendString:StringParams];
  
  // Set up HTTP Request (it will be released at end of callback or in dealloc)
  _httpRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[CompleteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
  [_httpRequest setTimeOutSeconds:30];  // Default is 10, which might be too short
  [_httpRequest setDelegate:self];
  [_httpRequest addRequestHeader:@"Accept" value:@"application/json"];
  [_httpRequest addRequestHeader:@"User-Agent" value:self.userAgent];
  [_httpRequest setUserInfo:[NSDictionary dictionaryWithObject:endpoint forKey:@"endpoint"]];
  
  if (isDelete){
    [_httpRequest setRequestMethod:@"DELETE"];
  }else{
    [_httpRequest setRequestMethod:@"GET"];
  }
  
  // Start the HTTP Request and wait for the response
  [_httpRequest startAsynchronous];
  
}

- (void)sendToMyGengoEndPoint:(NSString*)endpoint 
                             withParams:(NSDictionary*)params
                                  isPut:(BOOL)isPut{
  
  // Set up a completed url string that we'll append parameters to
  NSMutableString *CompleteURL = [NSMutableString stringWithString:@"http://"];
  
  // Add host (sandbox or production)
  [CompleteURL appendString:self.apiHost];
  
  // Add API version
  [CompleteURL appendFormat:@"/v%@/", self.apiVersion];
  
  // Add endpoint
  [CompleteURL appendString:endpoint];
  
  // Start assembling parameters to add to post body
  NSMutableDictionary *CompleteParams = [NSMutableDictionary dictionaryWithDictionary:params];
  
  // Add API sig & timestamp to params dictionary
  NSString *Timestamp = [self formattedTimestamp];
  [CompleteParams setObject:Timestamp forKey:@"ts"];
  [CompleteParams setObject:[self apiSignatureWithTimestamp:Timestamp] forKey:@"api_sig"];
  [CompleteParams setObject:_credentials.publicKey forKey:@"api_key"];
    
  // Add all params to the post body
  // Per the myGengo API, these params must be sorted alphabetically by key
  NSMutableString *CompleteBody = nil;
  NSArray *SortedKeys = [[CompleteParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
  for (NSString* Key in SortedKeys){
    if (CompleteBody == nil) {
      CompleteBody = [NSMutableString stringWithFormat:@"%@=%@", Key, [CompleteParams objectForKey:Key]];
    }else{
      [CompleteBody appendFormat:@"&%@=%@", Key, [CompleteParams objectForKey:Key]];
    }
  }
  
  // Set up HTTP Request (it will be released at end of callback or in dealloc)
  _httpRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:[CompleteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
  [_httpRequest setDelegate:self];
  [_httpRequest setTimeOutSeconds:30];  // Default is 10, which might be too short
  [_httpRequest addRequestHeader:@"Accept" value:@"application/json"];
  [_httpRequest addRequestHeader:@"User-Agent" value:self.userAgent];
  [_httpRequest addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
  [_httpRequest appendPostData:[[CompleteBody stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]];
  [_httpRequest setUserInfo:[NSDictionary dictionaryWithObject:endpoint forKey:@"endpoint"]];

  
  if (isPut){
    [_httpRequest setRequestMethod:@"PUT"];
  }else{
    [_httpRequest setRequestMethod:@"POST"];
  }
  
  // Start the HTTP Request and wait for the response
  [_httpRequest startAsynchronous];
  
}

# pragma mark ASIHTTPRequestDelegate

// Let the delegate know we've started a request
- (void)requestStarted:(ASIHTTPRequest *)request{
  NSString* EndPoint = [[request userInfo] objectForKey:@"endpoint"];
  if ([_delegate respondsToSelector:@selector(myGengoAPIHandlerDidStartLoad:fromEndPoint:)]){
    [_delegate myGengoAPIHandlerDidStartLoad:self fromEndPoint:EndPoint];
  }
}

// Returns ONLY the response parameter to the delegate if there were no errors
- (void)requestFinished:(ASIHTTPRequest *)request{
  NSError* Error = nil;
  NSString* EndPoint = [[request userInfo] objectForKey:@"endpoint"];
  
  // Decode JSON data into an NSDictionary
  NSDictionary* ResponseDictionary = [[JSONDecoder decoder] objectWithData:[request responseData] error:&Error];
 
  // If there were any errors in the decoding, return them to the delegate
  
  // If there was a parse error, just return it
  // If the server did not return 'ok', create a new error object and return that
  if ((Error == nil) && ![[ResponseDictionary objectForKey:@"opstat"] isEqualToString:@"ok"]){
    NSInteger Code = [[[ResponseDictionary objectForKey:@"err"] objectForKey:@"code"] integerValue];
    // NSString* Message = [[ResponseDictionary objectForKey:@"err"] objectForKey:@"msg"];
    // Attach the full response dictionary to the userInfo key
    Error = [NSError errorWithDomain:@"api.mygengo.com" code:Code userInfo:ResponseDictionary];
  }
  
  // If the response parameter was not found, create a new error object
  if ((Error == nil) && ![ResponseDictionary objectForKey:@"response"]){
    NSInteger Code = -1;  // Default error code
    // NSString* Message = @"TCMyGengoAPIHandler: Response object not found";
    // Attach the full response dictionary to the userInfo key
    Error = [NSError errorWithDomain:@"TCMyGengoAPIHandler" code:Code userInfo:ResponseDictionary];
  }
  
  if (Error != nil){  // Response with error
    if ([_delegate respondsToSelector:@selector(myGengoAPIHandlerDidFail:fromEndPoint:withError:)]){
      [_delegate myGengoAPIHandlerDidFail:self 
                             fromEndPoint:EndPoint
                                withError:Error];
    }  
  }else{              // Respond with success
  
    // If everything checks out, pass off ONLY the response dictionary to the delegate
    if ([_delegate respondsToSelector:@selector(myGengoAPIHandlerDidLoadDictionary:fromEndPoint:responseDictionary:)]){
      [_delegate myGengoAPIHandlerDidLoadDictionary:self 
                                       fromEndPoint:EndPoint
                                 responseDictionary:[ResponseDictionary objectForKey:@"response"]];
    }
  }
  
  // Clear out the request object and release it
  [request clearDelegatesAndCancel]; 
  [request release]; request = nil;
}

// Let the delegate know there was an error in the HTTP request
- (void)requestFailed:(ASIHTTPRequest *)request{
  NSString* EndPoint = [[request userInfo] objectForKey:@"endpoint"];

  // Pass the request error directly to the delegate
  if ([_delegate respondsToSelector:@selector(myGengoAPIHandlerDidFail:fromEndPoint:withError:)]){
    [_delegate myGengoAPIHandlerDidFail:self 
                            fromEndPoint:EndPoint 
                               withError:[request error]];
  }
  
  // Clear out the request object and release it
  [request clearDelegatesAndCancel]; 
  [request release]; request = nil;
}

#pragma mark Public

- (NSString *)apiHost{
  return [_credentials isSandboxed] ? SANDBOX_API_HOST : API_HOST;
}

- (NSString *)userAgent{
 return USER_AGENT;
}

- (NSString *)apiVersion{
 return API_VERSION;
}

- (void)getAccountStats{
  [self getFromMyGengoEndPoint:@"account/stats" withParams:nil isDelete:NO];
}

- (void)getAccountBalance{
  [self getFromMyGengoEndPoint:@"account/balance" withParams:nil isDelete:NO];
}

@end
