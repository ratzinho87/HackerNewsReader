//
//  HackerNewsApiClient.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "HackerNewsApiClient.h"
#import "AFNetworking.h"

@interface HackerNewsApiClient ()

@property (nonnull, readonly, strong) AFHTTPSessionManager *manager;

@end

@implementation HackerNewsApiClient

-(instancetype)initWithBaseUri:(NSString*)uri {
    _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:uri]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    return self;
}

-(void)fetchTopStories:(void (^)(NSArray<HackerNewsStory *>* _Nullable, NSError * _Nullable))completionHandler {
    [self fetchStoryListForUri:@"topstories.json" limit:10 completionHandler:completionHandler];
}

-(void)fetchNewStories:(void (^)(NSArray<HackerNewsStory *>* _Nullable, NSError * _Nullable))completionHandler {
    [self fetchStoryListForUri:@"newstories.json" limit:100 completionHandler:completionHandler];
}

-(void)fetchStoryListForUri:(NSString*)relativeUri
                      limit:(NSUInteger)limit
          completionHandler:(void (^)(NSArray<HackerNewsStory *>* _Nullable, NSError * _Nullable))completionHandler {
    
    [self.manager GET:relativeUri parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSArray class]]) {
            
            // we can't initiate a synchronous request on the completion queue, because we would deadlock waiting for the response
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray<HackerNewsStory *> *stories = [NSMutableArray<HackerNewsStory*> array];
                
                NSArray *responseArray = responseObject;
                for (NSNumber *identifier in responseArray) {
                    HackerNewsStory *story = [self fetchStoryWith:[identifier stringValue]];
                    if (story != nil && [story.type isEqualToString:@"story"] && story.url != nil) {
                        [stories addObject:story];
                        
                        if (stories.count == limit) {
                            break;
                        }
                    }
                }
                if (completionHandler != nil) {
                    completionHandler(stories, nil);
                }
            });
        } else {
            completionHandler(nil, [[NSError alloc] initWithDomain:NSURLErrorDomain code:500 userInfo:nil]); // we should put a better error here
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completionHandler != nil) {
            completionHandler(nil, error);
        }
    }];
}

-(HackerNewsStory *)fetchStoryWith:(NSString*)identifier {
    __block HackerNewsStory *story = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSString *relativeUri = [NSString stringWithFormat:@"item/%@.json", identifier];
    [self.manager GET:relativeUri parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            story = [[HackerNewsStory alloc] init];
            
            NSDictionary *responseDictionary = responseObject;
            story.by = [NSString stringWithFormat:@"%@", [responseDictionary objectForKey:@"by"]];
            story.identifier = [NSString stringWithFormat:@"%@", [responseDictionary objectForKey:@"id"]];
            story.score = (NSNumber *)[responseDictionary objectForKey:@"score"];
            story.time = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[responseDictionary objectForKey:@"time"]) doubleValue]];
            story.title = [NSString stringWithFormat:@"%@", [responseDictionary objectForKey:@"title"]];
            story.type = [NSString stringWithFormat:@"%@", [responseDictionary objectForKey:@"type"]];
            story.url = [NSString stringWithFormat:@"%@", [responseDictionary objectForKey:@"url"]];
        }
        
        dispatch_semaphore_signal(semaphore);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return story;
}

@end
