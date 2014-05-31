//
//  HNAPISubmission.m
//  newsyc
//
//  Created by Grant Paul on 3/30/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "HNKit.h"
#import "HNAPISubmission.h"
#import "HNNetworkActivityController.h"

#import "XMLDocument.h"

#import "NSDictionary+Parameters.h"

@implementation HNAPISubmission
@synthesize submission;

- (void)dealloc {
    [submission release];
    
    [super dealloc];
}

- (id)initWithSession:(HNSession *)session_ submission:(HNSubmission *)submission_ {
    if ((self = [super init])) {
        session = session_;
        submission = [submission_ retain];
        loadingState = kHNAPISubmissionLoadingStateReady;
    }
    
    return self;
}

- (void)_completedSuccessfully:(BOOL)successfully withError:(NSError *)error {
    loadingState = kHNAPISubmissionLoadingStateReady;

    if ([submission respondsToSelector:@selector(submissionCompletedSuccessfully:withError:)])
        [submission submissionCompletedSuccessfully:successfully withError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection_ {
    [HNNetworkActivityController networkActivityEnded];

    NSString *result = [[[NSString alloc] initWithData:received encoding:NSUTF8StringEncoding] autorelease];
    [received release];
    received = nil;
    [connection release];
    connection = nil;
    
    if (loadingState == kHNAPISubmissionLoadingStateFormTokens) {
        loadingState = kHNAPISubmissionLoadingStateFormSubmit;
        
        XMLDocument *document = [[XMLDocument alloc] initWithHTMLData:[result dataUsingEncoding:NSUTF8StringEncoding]];
        [document autorelease];
        
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
        [session addCookiesToRequest:request];
        
        if ([submission type] == kHNSubmissionTypeSubmission) {
            XMLElement *element = [document firstElementMatchingPath:@"//input[@name='fnid']"];
            
            NSDictionary *query = @{@"fnid": [element attributeWithName:@"value"],
                @"t": [submission title] ?: @"",
                @"u": [[submission destination] absoluteString] ?: @"",
                @"x": [submission body] ?: @""};

            [request setURL:[[NSURL URLWithString:@"/r" relativeToURL:kHNWebsiteURL] absoluteURL]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[[[query queryString] substringFromIndex:1] dataUsingEncoding:NSUTF8StringEncoding]];
        } else if ([submission type] == kHNSubmissionTypeVote) {
            NSString *dir = [submission direction] == kHNVoteDirectionUp ? @"up" : @"down";
            NSString *query = [NSString stringWithFormat:@"//a[@id='%@_%@']", dir, [[submission target] identifier]];
            XMLElement *element = [document firstElementMatchingPath:query];
            
            if (element == nil) {
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Voting not allowed."}];
                [self _completedSuccessfully:NO withError:error];
                return;
            } else {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", kHNWebsiteHost, [element attributeWithName:@"href"]]];
                [request setURL:url];
            }
        } else if ([submission type] == kHNSubmissionTypeReply) {
            XMLElement *element = [document firstElementMatchingPath:@"//input[@name='fnid']"];
            
            if (element == nil) {
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Replying not allowed."}];
                [self _completedSuccessfully:NO withError:error];
                return;
            } else {
                NSDictionary *query = @{@"fnid": [element attributeWithName:@"value"],
                    @"text": [submission body]};
                
                [request setURL:[[NSURL URLWithString:@"/r" relativeToURL:kHNWebsiteURL] absoluteURL]];
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [request setHTTPBody:[[[query queryString] substringFromIndex:1] dataUsingEncoding:NSUTF8StringEncoding]];
            }
        } else if ([submission type] == kHNSubmissionTypeFlag) {
            XMLElement *element = [document firstElementMatchingPath:@"//a[text()='flag' and starts-with(@href,'/r?fnid=')]"];
            
            if (element == nil) {
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Flagging not allowed."}];
                [self _completedSuccessfully:NO withError:error];
                return;
            } else {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", kHNWebsiteHost, [element attributeWithName:@"href"]]];
                [request setURL:url];
            }
        }
        
        connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [connection start];
        
        [HNNetworkActivityController networkActivityBegan];
    } else if (loadingState == kHNAPISubmissionLoadingStateFormSubmit) {
        [self _completedSuccessfully:YES withError:nil];
    }
}

- (void)connection:(NSURLConnection *)connection_ didFailWithError:(NSError *)error {
    [HNNetworkActivityController networkActivityEnded];

    [received release];
    received = nil;
    
    [self _completedSuccessfully:NO withError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [received appendData:data];
}

- (void)performSubmission {
    received = [[NSMutableData alloc] init];
    
    loadingState = kHNAPISubmissionLoadingStateFormTokens;
    
    NSURL *url = nil;
    
    if ([submission type] == kHNSubmissionTypeSubmission) {
        NSString *base = [NSString stringWithFormat:@"http://%@/%@", kHNWebsiteHost, @"submit"];
        url = [NSURL URLWithString:base];
    } else {
        url = [[submission target] URL];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [session addCookiesToRequest:request];
    
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
    
    [HNNetworkActivityController networkActivityBegan];
}

- (BOOL)isLoading {
    return loadingState != kHNAPISubmissionLoadingStateReady;
}

@end
