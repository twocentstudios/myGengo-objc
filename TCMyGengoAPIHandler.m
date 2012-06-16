//
//  TCMyGengoAPIHandler.m
//  
//
//  Created by Christopher Trott on 6/14/12.
//  Copyright (c) 2012 TwoCentStudios. All rights reserved.
//

#import "TCMyGengoAPIHandler.h"

@implementation TCMyGengoAPIHandler

#pragma mark NSObject

- (id)initWithPublicKey:(NSString*)publicKey 
             privateKey:(NSString*)privateKey
            isSandboxed:(BOOL)isSandboxed{
  
  if ((self = [super init])){
    _publicKey = [publicKey copy];
    _privateKey = [privateKey copy];
    _apiVersion = [NSString stringWithString:API_VERSION];
    _debug = NO;
    _userAgent = [NSString stringWithFormat:USER_AGENT, WRAPPER_VERSION];
    _sandboxed = isSandboxed;
    _apiHost = _sandboxed ? [NSString stringWithString:SANDBOX_API_HOST] : [NSString stringWithString:API_HOST];
  }
  
}

- (void)dealloc{
  [_publicKey release]; _publicKey = nil;
  [_privateKey release]; _privateKey = nil;
  [_apiVersion release]; _apiVersion = nil;
  [_userAgent release]; _userAgent = nil;
  [_apiHost release]; _apiHost = nil;
  [_httpRequest clearDelegatesAndCancel]; 
  [_httpRequest release]; _httpRequest = nil;
  [super dealloc];
}

#pragma mark Private

- (NSString*) formattedTimestamp{
  // We're using the Unix timestamp as the data. Not sure if this is right...
  return [NSString stringWithFormat:@"%.0f", [aDate timeIntervalSince1970]];
}

- (NSString*) apiSignatureWithTimestamp:(NSString*)timestamp{  
  NSString *key = _privateKey;
    
  const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
  const char *cData = [timestamp cStringUsingEncoding:NSASCIIStringEncoding];

  unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

  CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                     length:sizeof(cHMAC)];

  NSString *hash = [HMAC base64Encoding];
  return hash;
}

- (NSDictionary*) getFromMyGengoEndPoint:(NSString*)endpoint 
                              withParams:(NSDictionary*)params
                                isDelete:(BOOL)isDelete{
  
  // Set up a completed url string that we'll append parameters to
  NSMutableString *CompleteURL = [NSMutableString stringWithString:_apiHost];
  
  // Add API version
  [CompleteURL appendFormat:@"/v%@/", _apiVersion];
  
  // Add endpoint
  [CompleteURL appendString:endpoint];
  
  // Add API sig & timestamp
  NSString *Timestamp = [self formattedTimestamp];
  [CompleteURL appendFormat:@"?api_sig=%@", [self apiSignatureWithTimestamp:Timestamp]];
  [CompleteURL appendFormat:@"&ts=%@", Timestamp];
  
  // Add all params to the URI
  NSArray *Keys = [params allKeys];
  for (NSString* Key in Keys){
    [CompleteURL appendFormat:@"&%@=%@", Key, [params objectForKey:Key]];
  }
  
  // Set up HTTP Request
  _httpRequest = [[ASIHTTPRequest alloc] initWithURL:CompleteURL];
  [_httpRequest setDelegate:self];
  [_httpRequest addRequestHeader:@"Accept" value:@"application/json"];
  [_httpRequest addRequestHeader:@"User-Agent" value:_userAgent];
  
  if (isDelete){
    [request setRequestMethod:@"DELETE"];
  }else{
    [request setRequestMethod:@"GET"];
  }
  
  // Start the HTTP Request and wait for the response
  [_httpRequest startAsynchronous];
  
}
  // Add API sig
  [CompleteURL appendFormat:@"?api_sig=%@", [self apiSignatureWithTimestamp]];
  
  // Add all params to the URI
  NSArray *Keys = [params allKeys];
  for (NSString* Key in Keys){
    [CompleteURL appendFormat:@"&%@=%@", Key, [params objectForKey:Key]];
  }
  
  // Set up HTTP Request
  _httpRequest = [[ASIHTTPRequest alloc] initWithURL:CompleteURL];
  [_httpRequest setDelegate:self];
  [_httpRequest addRequestHeader:@"Accept" value:@"application/json"];
  [_httpRequest addRequestHeader:@"User-Agent" value:_userAgent];
  
  if (isDelete){
    [request setRequestMethod:@"DELETE"];
  }else{
    [request setRequestMethod:@"GET"];
  }
  
  // Start the HTTP Request and wait for the response
  [_httpRequest startAsynchronous];
  
}

# pragma mark ASIHTTPRequestDelegate

// Let the delegate know we've started a request
- (void)requestStarted:(ASIHTTPRequest *)request{
  if [_delegate respondsToSelector:@selector(myGengoAPIHandlerDidStartLoad:)]{
    [_delegate myGengoAPIHandlerDidStartLoad:self];
  }
}

// Returns ONLY the response parameter to the delegate if there were no errors
- (void)requestFinished:(ASIHTTPRequest *)request{
  NSError* Error = nil;
  
  // Decode JSON data into an NSDictionary
  NSDictionary* ResponseDictionary = [[JSONDecoder decoder] objectWithData:[request reponseData] error:&Error];
 
  // If there were any errors in the decoding, return them to the delegate
  
  // If there was a parse error, just return it
  // If the server did not return 'ok', create a new error object and return that
  if ((Error == nil) && ![[ResponseDictionary objectForKey:@"opstat"] isEqualToString:@"ok"]){
    NSInteger Code = [[[ResponseDictionary objectForKey:@"err"] objectForKey:@"code"] integerValue];
    NSString* Message = [[ResponseDictionary objectForKey:@"err"] objectForKey:@"msg"];
    // Attach the full response dictionary to the userInfo key
    Error = [NSError errorWithDomain:@"api.mygengo.com" code:Code userInfo:ResponseDictionary];
    [Error setLocalizedDescription:Message];
  }
  
  // If the response parameter was not found, create a new error object
  if ((Error == nil) && ![ResponseDictionary objectForKey:@"response"]){
    NSInteger Code = -1;  // Default error code
    NSString* Message = @"TCMyGengoAPIHandler: Response object not found";
    // Attach the full response dictionary to the userInfo key
    Error = [NSError errorWithDomain:@"TCMyGengoAPIHandler" code:Code userInfo:ResponseDictionary];
    [Error setLocalizedDescription:Message];
  }
  
  if (Error != nil){
    if [_delegate respondsToSelector:@selector(myGengoAPIHandlerDidFail:withError:)]{
      [_delegate myGengoAPIHandlerDidFail:self withError:Error];
    }  
    return;
  }
  
  // If everything checks out, pass off ONLY the response dictionary to the delegate
  if [_delegate respondsToSelector:@selector(myGengoAPIHandlerDidLoadDictionary:responseDictionary:)]{
    [_delegate myGengoAPIHandlerDidLoadDictionary:self responseDictionary:[ResponseDictionary objectForKey:@"response"]];
  }
}

// Let the delegate know there was an error in the HTTP request
- (void)requestFailed:(ASIHTTPRequest *)request{
  // Pass the request error directly to the delegate
  if [_delegate respondsToSelector:@selector(myGengoAPIHandlerDidFail:withError:)]{
    [_delegate myGengoAPIHandlerDidFail:self withError:[request error]];
  }  
}

@end
