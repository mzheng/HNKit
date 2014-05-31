//
//  HNEntry.m
//  newsyc
//
//  Created by Grant Paul on 3/4/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "NSURL+Parameters.h"

#import "HNKit.h"
#import "HNEntry.h"

#ifdef HNKIT_RENDERING_ENABLED
#import "HNObjectBodyRenderer.h"
#endif

@implementation HNEntry
@synthesize points, children, submitter, body, posted, parent, submission, title, destination;

#ifdef HNKIT_RENDERING_ENABLED
@synthesize renderer;

- (HNObjectBodyRenderer *)renderer {
    if (renderer != nil) return renderer;
    
    renderer = [[HNObjectBodyRenderer alloc] initWithObject:self];
    return renderer;
}
#endif

+ (id)identifierForURL:(NSURL *)url_ {
    if (![self isValidURL:url_]) return NO;
    
    NSDictionary *parameters = [url_ parameterDictionary];
    return @([parameters[@"id"] intValue]);
}

+ (NSString *)pathForURLWithIdentifier:(id)identifier_ infoDictionary:(NSDictionary *)info {
    return @"item";
}

+ (NSDictionary *)parametersForURLWithIdentifier:(id)identifier_ infoDictionary:(NSDictionary *)info {
    return @{@"id": identifier_};
}

+ (id)session:(HNSession *)session entryWithIdentifier:(id)identifier_ {
    return [self session:session objectWithIdentifier:identifier_];
}

- (BOOL)isComment {
    return ![self isSubmission];
}

- (BOOL)isSubmission {
    // Checking submission rather than something like title since this will be set
    // even when the entry hasn't been loaded.
    return [self submission] == nil;
}

- (void)loadFromDictionary:(NSDictionary *)response complete:(BOOL)complete {
    if (response[@"submission"]) {
        [self setSubmission:[HNEntry session:session entryWithIdentifier:response[@"submission"]]];
    }

    if (response[@"parent"]) {
        [self setParent:[HNEntry session:session entryWithIdentifier:response[@"parent"]]];

        // Set the submission property on the parent, as long as that's not the submission itself
        // (we want all submission objects to have a submission property value of nil)
        if (![[[self parent] identifier] isEqual:[[self submission] identifier]]) {
            [[self parent] setSubmission:[self submission]];
        }
    }

    if (response[@"url"] != nil) [self setDestination:[NSURL URLWithString:response[@"url"]]];
    if (response[@"user"] != nil) [self setSubmitter:[HNUser session:session userWithIdentifier:response[@"user"]]];
    if (response[@"body"] != nil) [self setBody:response[@"body"]];
    if (response[@"date"] != nil) [self setPosted:response[@"date"]];
    if (response[@"title"] != nil) [self setTitle:response[@"title"]];
    if (response[@"points"] != nil) [self setPoints:[response[@"points"] intValue]];
    
    if (response[@"children"] != nil) {
        NSMutableArray *comments = [NSMutableArray array];

        for (NSDictionary *child in response[@"children"]) {
            HNEntry *childEntry = [HNEntry session:session entryWithIdentifier:child[@"identifier"]];
            
            [childEntry setParent:self];
            [childEntry setSubmission:[self submission] ?: self];

            BOOL complete = (child[@"children"] != nil);
            [childEntry loadFromDictionary:child complete:complete];

            [comments addObject:childEntry];
        }

        NSArray *allEntries = [(pendingMoreEntries ? : @[]) arrayByAddingObjectsFromArray:comments];
        [self setEntries:allEntries];
    }
    
    if (response[@"numchildren"] != nil) {
        NSInteger count = [response[@"numchildren"] intValue];
        [self setChildren:count];
    } else {
        NSInteger count = [[self entries] count];
        
        for (HNEntry *child in [self entries]) {
            count += [child children];
        }
        
        [self setChildren:count];
    }

    [super loadFromDictionary:response complete:complete];
}

@end
