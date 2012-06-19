//
//  TCMyGengoAPIHandler.h
//  
//  Copyright 2012 Christopher Trott
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "ASIHTTPRequest.h"
#import "JSONKit.h"

#define API_HOST @"api.mygengo.com"
#define SANDBOX_API_HOST @"api.sandbox.mygengo.com"
#define API_VERSION @"1.1"
#define WRAPPER_VERSION @"0.1"
#define USER_AGENT @"myGengo ObjC Library; Version %@; http://twocentstudios.com/;" //@"myGengo Ruby Library; Version 1.8; http://mygengo.com/;"

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


///////////////////////////////////////////////////////////////////////////////////////
// Accounts and Languages

// Stats for the current account
- (void)getAccountStats;

// Balance for the current account
- (void)getAccountBalance;

// Currently supported languages
- (void)getServiceLanguages;

// Currently supported language pairs
// Options:
// lc_src - Optional two-character language code to filter the results on
- (void)getServiceLanguagePairs:(NSDictionary *)params;


///////////////////////////////////////////////////////////////////////////////////////
// Translation Job

// Gets info on a single job
// Options:
// id, pre_mt (machine translation)
- (void)getTranslationJob:(NSDictionary *)params;

// Gets list of jobs
// Options:
// status, timestamp_after, count
- (void)getTranslationJobs:(NSDictionary *)params;

// Gets a group of jobs that were submitted together
// Options:
// id - id of the group
- (void)getTranslationJobGroup:(NSDictionary *)params;

// Gets feedback previously submitted for a single job
// Required:
// id - id of the job
- (void)getTranslationJobFeedback:(NSDictionary *)params;

// [DEPRECATED in v2] Posts a new translation job to the server
// Required:
// dictionary of job params for key "job"
// job -> type/slug/body_src/lc_src/lc_tgt/tier/auto_approve/comment/callback_url/custom_data
- (void)postTranslationJob:(NSDictionary *)params;

// Posts a new translation job or jobs to the server
// Required:
// array of jobs for key "jobs"
// dictionary of job params for each job
// job -> type/slug/body_src/lc_src/lc_tgt/tier/auto_approve/comment/callback_url/custom_data
// Optional:
// as_group - 0 or 1
- (void)postTranslationJobs:(NSDictionary *)params;

// Posts a new translation job or jobs to the server for a quote
// Required:
// array of jobs for key "jobs"
// dictionary of job params for each job
// job -> type/slug/body_src/lc_src/lc_tgt/tier
- (void)postTranslationJobsForQuote:(NSDictionary *)params;

// Updates the specified translation job with new information
// Required:
// id - id of job
// action - revise, approve, reject
// additional parameters based on the action (see API docs)
- (void)updateTranslationJob:(NSDictionary *)params;

// Deletes the specified translation job
// Required:
// id - id of job
- (void)deleteTranslationJob:(NSDictionary *)params;

///////////////////////////////////////////////////////////////////////////////////////
// Comments

// Gets all the comments for a job
// Required:
// id - id of the job
- (void)getTranslationJobComments:(NSDictionary *)params;

// Posts a new comment on a job
// Required:
// id - id of the job
// body - full text of the comment
- (void)postTranslationJobComment:(NSDictionary *)params;


///////////////////////////////////////////////////////////////////////////////////////
// Revisions

// Gets a specific revision to a job
// Required:
// id - id of the job
// rev_id - id of the revision
- (void)getTranslationJobRevision:(NSDictionary *)params;

// Gets a list of revisions for a job
// Required:
// id - id of the job
- (void)getTranslationJobRevisions:(NSDictionary *)params;

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
