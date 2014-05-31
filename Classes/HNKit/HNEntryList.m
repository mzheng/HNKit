//
//  HNEntryList.m
//  newsyc
//
//  Created by Grant Paul on 8/12/11.
//  Copyright (c) 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "HNEntryList.h"
#import "HNEntry.h"

@interface HNEntryList ()

@property (nonatomic, retain) HNUser *user;

@end

@implementation HNEntryList
@synthesize user;

+ (NSDictionary *)infoDictionaryForURL:(NSURL *)url_ {
    if (![self isValidURL:url_]) return nil;

    NSDictionary *parameters = [url_ parameterDictionary];
    if (parameters[@"id"] != nil) return @{@"user": parameters[@"id"]};
    else return nil;
}

+ (id)identifierForURL:(NSURL *)url_ {
    if (![self isValidURL:url_]) return nil;
    
    NSString *path = [url_ path];
    if ([path hasSuffix:@"/"]) path = [path substringToIndex:[path length] - 2];
    
    return path;
}

+ (NSString *)pathForURLWithIdentifier:(id)identifier_ infoDictionary:(NSDictionary *)info {
    return identifier_;
}

+ (NSDictionary *)parametersForURLWithIdentifier:(id)identifier_ infoDictionary:(NSDictionary *)info {
    if (info != nil && info[@"user"] != nil) {
        return @{@"id": info[@"user"]};
    } else {
        return @{};
    }
}

+ (id)session:(HNSession *)session entryListWithIdentifier:(HNEntryListIdentifier)identifier_ user:(HNUser *)user_ {
    NSDictionary *info = nil;
    if (user_ != nil) info = @{@"user": [user_ identifier]};
    
    return [self session:session objectWithIdentifier:identifier_ infoDictionary:info];
}

+ (id)session:(HNSession *)session entryListWithIdentifier:(HNEntryListIdentifier)identifier_ {
    return [self session:session entryListWithIdentifier:identifier_ user:nil];
}

- (void)loadInfoDictionary:(NSDictionary *)info {
    if (info != nil) {
        NSString *identifier_ = info[@"user"];
        [self setUser:[HNUser session:session userWithIdentifier:identifier_]];
    }
}

- (NSDictionary *)infoDictionary {
    if (user != nil) {
        return @{@"user": [user identifier]};
    } else {
        return [super infoDictionary];
    }
}

- (void)loadFromDictionary:(NSDictionary *)response complete:(BOOL)complete {
    NSMutableArray *children = [NSMutableArray array];
    
    for (NSDictionary *entryDictionary in response[@"children"]) {
        HNEntry *entry = [HNEntry session:session entryWithIdentifier:entryDictionary[@"identifier"]];
        [entry loadFromDictionary:entryDictionary complete:NO];
        [children addObject:entry];
    }

    NSArray *allEntries = [(pendingMoreEntries ? : @[]) arrayByAddingObjectsFromArray:children];
    [self setEntries:allEntries];

    [super loadFromDictionary:response complete:complete];
}

@end
