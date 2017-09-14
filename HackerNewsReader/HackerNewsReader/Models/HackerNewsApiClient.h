//
//  HackerNewsApiClient.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HackerNewsStory.h"

@interface HackerNewsApiClient : NSObject

-(void)fetchTopStories:(nullable void (^)(NSArray<HackerNewsStory *>* _Nullable, NSError * _Nullable))completionHandler;
-(void)fetchNewStories:(nullable void (^)(NSArray<HackerNewsStory *>* _Nullable, NSError * _Nullable))completionHandler;

@end
