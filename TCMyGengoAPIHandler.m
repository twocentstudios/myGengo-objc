//
//  TCMyGengoAPIHandler.m
//  
//
//  Created by Christopher Trott on 6/14/12.
//  Copyright (c) 2012 TwoCentStudios. All rights reserved.
//

#import "TCMyGengoAPIHandler.h"

@implementation TCMyGengoAPIHandler


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

- (NSString*) apiSignatureWithTimestamp{  
  NSString *key = _privateKey;
  
  // We're using the Unix timestamp as the data. Not sure if this is right...
  NSString *data = [NSString stringWithFormat:@"%.0f", [aDate timeIntervalSince1970]];
  
  const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
  const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];

  unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

  CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                     length:sizeof(cHMAC)];

  NSString *hash = [HMAC base64Encoding];
  return hash;
}
@end
