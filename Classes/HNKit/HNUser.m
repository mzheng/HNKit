//
//  HNUser.m
//  newsyc
//
//  Created by Grant Paul on 3/4/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "NSURL+Parameters.h"

#import "HNKit.h"
#import "HNUser.h"

@implementation HNUser
@synthesize karma, average, created, about;

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
    return parameters[@"id"];
}

+ (NSString *)pathForURLWithIdentifier:(id)identifier_ infoDictionary:(NSDictionary *)info {
    return @"user";
}

+ (NSDictionary *)parametersForURLWithIdentifier:(id)identifier_ infoDictionary:(NSDictionary *)info {
    if (identifier_ != nil) return @{@"id": identifier_};
    else return @{};
}

+ (id)session:(HNSession *)session userWithIdentifier:(id)identifier_ {
    return [self session:session objectWithIdentifier:identifier_];
}

- (void)loadFromDictionary:(NSDictionary *)dictionary complete:(BOOL)complete {
    [self setAbout:dictionary[@"about"]];
    [self setKarma:[dictionary[@"karma"] intValue]];
    [self setAverage:[dictionary[@"average"] floatValue]];
    [self setCreated:[dictionary[@"created"] stringByRemovingSuffix:@" ago"]];

    [super loadFromDictionary:dictionary complete:complete];
}

@end
