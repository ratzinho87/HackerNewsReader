//
//  NewsStoriesDataSource.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NewsStory+CoreDataClass.h"

extern NSString *const SavedStoriesChangedNotification;

@interface NewsStoriesDataSource : NSObject

+(instancetype)sharedInstance;

-(NSFetchedResultsController<NewsStory *>*)getTopStories;
-(NSFetchedResultsController<NewsStory *>*)getNewStories;
-(NSFetchedResultsController<NewsStory *>*)getSavedStories;

-(void)saveStory:(NewsStory *)story;
-(void)unsaveStory:(NewsStory *)story;

-(void)markStoryAsRead:(NewsStory *)story;
-(void)markStoryAsUnread:(NewsStory *)story;

-(void)updateStories:(nullable void (^)())completionHandler;

@end
