//
//  TCMyGengoAPIHandler.h
//  
//
//  Created by Christopher Trott on 6/14/12.
//  Copyright (c) 2012 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#define API_HOST @"api.mygengo.com"
#define SANDBOX_API_HOST @"api.sandbox.mygengo.com"
#define VERSION @"0.1"

// Classes that use the API Handler should implement the delegate protocol
// in order to receive feedback as to the status of their requests and
// the responses themselves from the server

@protocol TCMyGengoAPIHandlerDelegate <NSObject>
@optional
- (void)myGengoAPIHandlerDidStartLoad: (TCMyGengoAPIHandler*)handler;
- (void)myGengoAPIHandlerDidLoadDictionary: (TCMyGengoAPIHandler*)handler 
                        responseDictionary: (NSDictionary*)response;
- (void)myGengoAPIHandlerDidFail: (TCMyGengoAPIHandler*)handler 
                       withError: (NSError*)error;
@end

@interface TCMyGengoAPIHandler : NSObject{ 
  BOOL _sandbox;
  NSString* _publicKey;
  NSString* _privateKey;
  NSString* _apiVersion;
  BOOL _debug;
  NSString* _userAgent;
  NSString* _apiHost;
}

// Default initializer
- (id)initWithPublicKey:(NSString*)publicKey 
             privateKey:(NSString*)privateKey
            isSandboxed:(BOOL)isSandboxed;


// Creates HMAC SHA-1 hash of private key signed with current time
// in GMT converted to an int then a string
- (NSString*) apiSignatureWithTimestamp;

// Formats a GET request based on a provided endpoint URL and parameters
// and returns an NSDictionary with the response
- (NSDictionary*) getFromMyGengoEndPoint:(NSString*)endpoint 
                              withParams:(NSDictionary*)params;

// Formats a POST/PUT/DELETE request based on a provided endpoint URL and parameters
// and returns an NSDictionary with the response
- (NSDictionary*) sendToMyGengoEndPoint:(NSString*)endpoint
                             withParams:(NSDictionary*)params;


// Stats for the current account
- (void) getAccountStats;

// Balance for the current account
- (void) getAccountBalance;



@end
