//
//  NewsStoriesDataSource.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewsStoriesDataSource.h"
#import "HackerNewsApiClient.h"

@interface NewsStoriesDataSource()

@property (nonatomic, strong) NSPersistentContainer *persistentContainer;

@end

@implementation NewsStoriesDataSource

+(instancetype)sharedInstance {
    static NewsStoriesDataSource *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self.persistentContainer = [NSPersistentContainer persistentContainerWithName:@"Model"];
    [self.persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull storeDescription, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Failed to create persistent store. error: %@", error);
        }
    }];
    return self;
}

-(NSArray<NewsStory *>*)getTopStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isTop == 1"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO];
    return [self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:self.persistentContainer.viewContext];
}

-(NSArray<NewsStory *>*)getNewStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isNew == 1"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publishingTime" ascending:NO];
    return [self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:self.persistentContainer.viewContext];
}

-(NSArray<NewsStory *>*)getSavedStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSaved == 1"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publishingTime" ascending:NO];
    return [self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:self.persistentContainer.viewContext];
}

-(NSArray<NewsStory *>*)fetchWithPredicate:(NSPredicate*)predicate
                            sortDescriptor:(NSSortDescriptor *)sortDescriptor
                                   context:(NSManagedObjectContext*)context {
    NSFetchRequest<NewsStory *> *fetchRequest = [NewsStory fetchRequest];
    fetchRequest.predicate = predicate;
    if (sortDescriptor != nil) {
        fetchRequest.sortDescriptors = [NSArray<NSSortDescriptor *> arrayWithObject:sortDescriptor];
    }
    return [context executeFetchRequest:fetchRequest error:nil];
}


-(void)saveStory:(NewsStory *)story {
    story.isSaved = YES;
    [self.persistentContainer.viewContext save:nil];
}

-(void)unsaveStory:(NewsStory *)story {
    story.isSaved = NO;
    [self.persistentContainer.viewContext save:nil];
}

-(void)markStoryAsRead:(NewsStory *)story {
    story.isRead = YES;
    [self.persistentContainer.viewContext save:nil];
}

-(void)markStoryAsUnread:(NewsStory *)story {
    story.isRead = NO;
    [self.persistentContainer.viewContext save:nil];
}

-(void)updateStories:(nullable void (^)())completionHandler {
    HackerNewsApiClient *client = [[HackerNewsApiClient alloc] initWithBaseUri:@"https://hacker-news.firebaseio.com/v0/"];
    
    [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * _Nonnull context) {
        [client fetchTopStories:^(NSArray<HackerNewsStory *> * _Nullable stories, NSError * _Nullable error) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isTop == 1"];
            [self updateStoryListWithContext:context predicate:predicate newStories:stories setIsTopToYes:YES setIsNewToYes:NO];
            [context save:nil];
            
            [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * _Nonnull context) {
                [client fetchNewStories:^(NSArray<HackerNewsStory *> * _Nullable stories, NSError * _Nullable error) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isNew == 1"];
                    [self updateStoryListWithContext:context predicate:predicate newStories:stories setIsTopToYes:NO setIsNewToYes:YES];
                    
                    // Cleanup: we don't show or use stories that are neither top, new or saved
                    NSFetchRequest<NewsStory *> *fetchRequestForOldStories = [NewsStory fetchRequest];
                    fetchRequestForOldStories.predicate = [NSPredicate predicateWithFormat:@"isTop == 0 AND isNew == 0 and isSaved == 0"];
                    NSArray<NewsStory *> *oldStories = [context executeFetchRequest:fetchRequestForOldStories error:nil];
                    
                    for (NewsStory *oldStory in oldStories) {
                        [context deleteObject:oldStory];
                    }                    
                    [context save:nil];
                    
                    if (completionHandler != nil) {
                        dispatch_async(dispatch_get_main_queue(), ^{                            
                            completionHandler();
                        });
                    }
                }];
            }];
        }];
    }];
}

-(void)updateStoryListWithContext:(NSManagedObjectContext*)context
                        predicate:(NSPredicate*)predicate
                       newStories:(NSArray<HackerNewsStory *> *)newStories
                       setIsTopToYes:(BOOL)isTop
                       setIsNewToYes:(BOOL)isNew {
    
    NSArray<NewsStory *> *dbStories =  [self fetchWithPredicate:predicate sortDescriptor:nil context:context];
    // Transform to a dictionary, so we can easily retrieve stories by id
    NSMutableDictionary<NSString *, NewsStory *> *dbStoriesDict = [NSMutableDictionary<NSString *, NewsStory *> dictionary];
    for (NewsStory *dbStory in dbStories) {
        [dbStoriesDict setObject:dbStory forKey:dbStory.identifier];
    }
    
    for (HackerNewsStory *story in newStories) {
        NewsStory *dbStory = [dbStoriesDict valueForKey:story.identifier];
        if (dbStory != nil) {
            // Update the existing story. HN moderators sometimes edit the title and even the url
            [self updateStory:dbStory with:story];
            // Removing the updated object, so that all is left at the end can have its isTop flag reset
            [dbStoriesDict removeObjectForKey:story.identifier];
        } else {
            dbStory = [[NewsStory alloc] initWithContext:context];
            [self updateStory:dbStory with:story];
            dbStory.isTop = isTop;
            dbStory.isNew = isNew;
            dbStory.isRead = NO;
            dbStory.isSaved = NO;
        }
    }
    
    // All stories left in the dictionary were not found in the latest update and so they are no longer top
    for (NewsStory *dbStory in dbStoriesDict.allValues) {
        if (isTop) {
            dbStory.isTop = NO;
        }
        if (isNew) {
            dbStory.isNew = NO;
        }
    }
}

-(void)updateStory:(NewsStory*)dbStory with:(HackerNewsStory*)story {
    dbStory.identifier = story.identifier;
    dbStory.title = story.title;
    dbStory.publishingTime = story.time;
    dbStory.url = story.url;
    dbStory.score = [story.score intValue];
}

@end
