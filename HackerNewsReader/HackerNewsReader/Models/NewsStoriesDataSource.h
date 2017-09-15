//
//  NewsStoriesDataSource.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewsStory+CoreDataClass.h"

extern NSString * __nonnull const SavedStoriesChangedNotification;

@interface NewsStoriesDataSource : NSObject

+(nonnull instancetype)sharedInstance;

-(nullable NSFetchedResultsController<NewsStory *>*)getTopStories;
-(nullable NSFetchedResultsController<NewsStory *>*)getNewStories;
-(nullable NSFetchedResultsController<NewsStory *>*)getSavedStories;

-(void)saveStory:(nonnull NewsStory *)story;
-(void)unsaveStory:(nonnull NewsStory *)story;

-(void)markStoryAsRead:(nonnull NewsStory *)story;
-(void)markStoryAsUnread:(nonnull NewsStory *)story;

-(void)updateStories:(nullable void (^)())completionHandler;

@end
