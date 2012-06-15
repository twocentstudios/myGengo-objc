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
  [super dealloc];
}
@end
