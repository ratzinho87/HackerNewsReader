//
//  NewsStory+CoreDataClass.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewsStory+CoreDataClass.h"

@implementation NewsStory

- (NSURL *)domainIconUri {
    NSURLComponents * components = [[NSURLComponents alloc] initWithString:self.url];
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://icons.better-idea.org/icon?url=%@&size=16..32..64", components.host]];
}

@end
