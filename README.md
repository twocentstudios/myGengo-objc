myGengo-objc
------------
Unofficial [myGengo](http://mygengo.com/api) API Wrapper for Objective-C

## Platform
* Tested on iOS only (although should probably work on OS X too).
* Not ARC, but wouldn't be difficult to port.
* Targets version V1.1 of the myGengo API, but should be compatible with V2.0 when it is formally released.
* Is asynchronous, and uses delegates heavily (no blocks).
* You must provide your own public & private API keys from the myGengo website or sandbox website.
* Tested, but not significantly, and not for every conceivable usage, so use with caution.
* Somewhat un-objc-like in that it expects intimate knowledge of the API parameters (but therefore more flexible).
* I imagine it should work for as far back as iOS 3.0, but I'm only planning on using it for > 4.0.

## Requirements (iOS)
I would pull these from github and drag the source files into your project.

* [APIHTTPRequest](https://github.com/pokeb/asi-http-request/tree) and all its requirements including:
	* CFNetwork.framework
	* MobileCoreServices.framework
	* SystemConfiguration.framework
	* CoreGraphics.framework
	* libz.dylib
* [JSONKit](https://github.com/johnezang/JSONKit)
* CommonCrypto (included by default in iOS but for older versions (maybe iOS 3.0?) you may have to include Security.framework).

## Quick Start

The .h file is moderately well documented, but you should also see the myGengo API documentation for specifically required parameters for each call.

### Credentials

First, initialize the singleton class that encapsulates your credentials. You only have to do this once and these credentials will be shared to all your API Wrapper instances.

	// AppDelegate -> application:didFinishLaunchingWithOptions:
	
	[[TCMyGengoAPICredentials sharedCredentials] setCredentialsWithPublicKey:SANDBOX_PUBLIC_KEY privateKey:SANDBOX_PRIVATE_KEY isSandboxed:YES];
	
### Handler

Create a new instance of TCMyGengoAPIHandler for each controller and initialize it with your shared credentials object.

	// MyViewController -> init
	// (Assuming you have a _handler instance variable)	
	_handler = [[TCMyGengoAPIHandler alloc] initWithDelegate:self credentials:[TCMyGengoAPICredentials sharedCredentials]];
	
Or you can use the convenience initializer which assumes you're using `[TCMyGengoAPICredentials sharedCredentials]`.

	// MyViewController -> init (alternate)
	
	_handler = [[TCMyGengoAPIHandler alloc] initWithDelegate:self];

### Making Calls

Making a call is pretty straightforward. Most methods take a generic NSDictionary of params. Check the myGengo API docs or the .h file for usage info. Any call that needs a job id should have a key for "id" for example.

	// Simple get call with no parameters
	[_handler getAccountBalance];
	
	// Getting info about a translation job 
	[_handler getTranslationJob:[NSDictionary dictionaryWithObjectsAndKeys:@"123456", @"id", @"0", @"pre_mt", nil]];
	
	// Posting a translation job
	NSDictionary *Job1 = [NSDictionary dictionaryWithObjectsAndKeys:@"text", @"type", 
                       @"Test Slug", @"slug", 
                       @"Hallo zusammen", @"body_src", 
                       @"de", @"lc_src", 
                       @"en", @"lc_tgt", 
                       @"standard", @"tier", nil];
    NSArray *JobArray = [NSArray arrayWithObject:Job1];
	[_handler postTranslationJobs:[NSDictionary dictionaryWithObject:JobArray forKey:@"jobs"]];
	
See the tests branch for more examples.

### Delivery
	
Now that you've made the call, implement the delegate methods. Each delegate method returns the endpoint it was called to (ex. "account/balance") in case you want to implement different logic for different calls.

`StartLoad` will be triggered when the request is sent to the server. (Hint: you can start an activity indicator here).

	- (void)myGengoAPIHandlerDidStartLoad:(TCMyGengoAPIHandler *)handler fromEndPoint:(NSString *)endpoint;

`DidLoadDictionary` will be triggered once the data has been received from the server, parsed, and delivered in an NSDictionary. The server status field will not be included, only the response. Some calls do not return a response, but rest assured, if this function is called everything went through okay.

	- (void)myGengoAPIHandlerDidLoadDictionary:(TCMyGengoAPIHandler *)handler fromEndPoint:(NSString *)endpoint responseDictionary:(NSDictionary *)response;
	
`DidFail` will be triggered when a request fails. The error field is pretty descriptive. It will tell you whether there was an error with the request (ASIHTTPRequest), an error parsing the data (JSONKit), or an error with the data that was sent (myGengo).

	- (void)myGengoAPIHandlerDidFail:(TCMyGengoAPIHandler *)handler fromEndPoint:(NSString *)endpoint withError:(NSError *)error;
	
## TODO

* translate/job/{id}/preview (GET) is not yet implemented.
* translate/jobs/{id} (PUT) is not yet implemented (although it's singular version is).
* ARC compatibility.
* Optional callbacks with blocks.
* OS X compatibility.
* Example project.

## License

Copyright 2012 Christopher Trott

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

See the License for the specific language governing permissions andlimitations under the License.