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
#import "ASIHTTPRequest.h"
#import "JSONKit.h"

#define API_HOST @"http://api.mygengo.com"
#define SANDBOX_API_HOST @"http://api.sandbox.mygengo.com"
#define API_VERSION @"1.1"
#define WRAPPER_VERSION @"0.1"
#define USER_AGENT @"myGengo ObjC Library; Version %@; http://mygengo.com/;"

// Classes that use the API Handler should implement the delegate protocol
// in order to receive feedback as to the status of their requests and
// the responses themselves from the server

@class TCMyGengoAPIHandler;

@protocol TCMyGengoAPIHandlerDelegate <NSObject>
@optional
- (void)myGengoAPIHandlerDidStartLoad: (TCMyGengoAPIHandler*)handler 
                         fromEndPoint: (NSString*)endpoint;
- (void)myGengoAPIHandlerDidLoadDictionary: (TCMyGengoAPIHandler*)handler
                              fromEndPoint: (NSString*)endpoint
                        responseDictionary: (NSDictionary*)response;
- (void)myGengoAPIHandlerDidFail: (TCMyGengoAPIHandler*)handler 
                    fromEndPoint: (NSString*)endpoint
                       withError: (NSError*)error;
@end

// Credentials are managed in a singleton. Create the singleton once in
// the AppDelegate, set your credentials, and pass the singleton
// to each API handler instance that you create.

@interface TCMyGengoAPICredentials : NSObject{
  BOOL _isSandboxed;
  NSString* _publicKey;
  NSString* _privateKey;
}

@property (nonatomic, readonly) NSString *publicKey;
@property (nonatomic, readonly) NSString *privateKey;
@property (nonatomic, readonly) BOOL isSandboxed;

+ (TCMyGengoAPICredentials *)sharedCredentials;
- (void)setCredentialsWithPublicKey:(NSString *)publicKey
                         privateKey:(NSString *)privateKey
                        isSandboxed:(BOOL)isSandboxed;

@end

@interface TCMyGengoAPIHandler : NSObject <ASIHTTPRequestDelegate>{ 
  TCMyGengoAPICredentials* _credentials;
  ASIHTTPRequest* _httpRequest;
  id <TCMyGengoAPIHandlerDelegate> _delegate;
}

@property (nonatomic, readonly) TCMyGengoAPICredentials *credentials;
@property (nonatomic, readonly) NSString *apiHost;
@property (nonatomic, readonly) NSString *userAgent;
@property (nonatomic, readonly) NSString *apiVersion;

// Default initializer
- (id)initWithDelegate:(id<TCMyGengoAPIHandlerDelegate>)delegate Credentials:(TCMyGengoAPICredentials *)credentials;
// Shortcut for initializing with [TCMyGengoCredentialsManager sharedCredentials]
- (id)initWithDelegate:(id<TCMyGengoAPIHandlerDelegate>)delegate;

// Stats for the current account
- (void) getAccountStats;

// Balance for the current account
- (void) getAccountBalance;

# pragma mark Private

// Helper function for returning a UNIX timestamp intergerized and returned as a string
- (NSString *)formattedTimestamp;

// Creates HMAC SHA-1 hash of private key signed with current time
// in GMT converted to an int then a string
- (NSString *)apiSignatureWithTimestamp:(NSString *)timestamp;  

// Formats a GET/DELETE request based on a provided endpoint URL and parameters
// and returns an NSDictionary with the response
- (void)getFromMyGengoEndPoint:(NSString *)endpoint 
                              withParams:(NSDictionary*)params
                                isDelete:(BOOL)isDelete;

// Formats a POST/PUT request based on a provided endpoint URL and parameters
// and returns an NSDictionary with the response
- (void)sendToMyGengoEndPoint:(NSString *)endpoint
                             withParams:(NSDictionary*)params
                                  isPut:(BOOL)isPut;






@end
