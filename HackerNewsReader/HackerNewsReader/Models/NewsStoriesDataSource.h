//
//  NewsStoriesDataSource.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewsStory+CoreDataClass.h"

@interface NewsStoriesDataSource : NSObject

+(instancetype)sharedInstance;

-(NSArray<NewsStory *>*)getTopStories;
-(NSArray<NewsStory *>*)getNewStories;
-(NSArray<NewsStory *>*)getSavedStories;

-(void)updateStories:(nullable void (^)())completionHandler;

@end
