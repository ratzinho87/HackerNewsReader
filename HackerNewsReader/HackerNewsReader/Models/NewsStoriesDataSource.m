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

@property (nonatomic, strong) dispatch_semaphore_t updateSemaphore;

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
    self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    [self.persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull storeDescription, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Failed to create persistent store. error: %@", error);
        }
    }];
    self.updateSemaphore = dispatch_semaphore_create(1);
    return self;
}

-(NSFetchedResultsController<NewsStory *>*)getTopStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isTop == 1"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO];
    return [self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:self.persistentContainer.viewContext];
}

-(NSFetchedResultsController<NewsStory *>*)getNewStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isNew == 1"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publishingTime" ascending:NO];
    return [self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:self.persistentContainer.viewContext];
}

-(NSFetchedResultsController<NewsStory *>*)getSavedStories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSaved == 1"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publishingTime" ascending:NO];
    return [self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:self.persistentContainer.viewContext];
}

-(NSFetchedResultsController<NewsStory *>*)fetchWithPredicate:(NSPredicate*)predicate
                            sortDescriptor:(NSSortDescriptor *)sortDescriptor
                                   context:(NSManagedObjectContext*)context {
    NSFetchRequest<NewsStory *> *fetchRequest = [NewsStory fetchRequest];
    fetchRequest.predicate = predicate;
    if (sortDescriptor != nil) {
        fetchRequest.sortDescriptors = [NSArray<NSSortDescriptor *> arrayWithObject:sortDescriptor];
    }
    NSFetchedResultsController<NewsStory *> *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                              managedObjectContext:context
                                                                                                sectionNameKeyPath:nil cacheName:nil];
    [controller performFetch:nil];
    return controller;
}


-(void)saveStory:(NewsStory *)story {
    story.isSaved = YES;
    [self saveContext:self.persistentContainer.viewContext];
}

-(void)unsaveStory:(NewsStory *)story {
    story.isSaved = NO;
    [self saveContext:self.persistentContainer.viewContext];
}

-(void)markStoryAsRead:(NewsStory *)story {
    story.isRead = YES;
    [self saveContext:self.persistentContainer.viewContext];
}

-(void)markStoryAsUnread:(NewsStory *)story {
    story.isRead = NO;
    [self saveContext:self.persistentContainer.viewContext];
}

-(void)saveContext:(NSManagedObjectContext *)context {
    NSError *saveError = nil;
    [context save:&saveError];
    if (saveError != nil) {
        NSLog(@"Failed to save context %@. error(domain: %@, code:%ld, info:%@)", context.name, saveError.domain, (long)saveError.code, saveError.userInfo);
    }
}

-(void)updateStories:(nullable void (^)())completionHandler {    ;
    if (dispatch_semaphore_wait(self.updateSemaphore, 0) != 0) {
        NSLog(@"Update already in progress, so skipping.");
        return;
    }
    
    HackerNewsApiClient *client = [[HackerNewsApiClient alloc] initWithBaseUri:@"https://hacker-news.firebaseio.com/v0/"];
    
    void(^completion)() = ^{
        dispatch_semaphore_signal(self.updateSemaphore);
        if (completionHandler != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
        }
    };
    
    [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * _Nonnull context) {
        [client fetchTopStories:^(NSArray<HackerNewsStory *> * _Nullable stories, NSError * _Nullable error) {
            if (stories == nil || error != nil) {
                NSLog(@"Got error while fetching top stories. error=%@", error);
                completion();
                return;
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isTop == 1"];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publishingTime" ascending:NO];
            [self updateStoryListWithContext:context predicate:predicate sortDescriptor:sortDescriptor newStories:stories setIsTopToYes:YES setIsNewToYes:NO];
            [self saveContext:context];
            
            [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * _Nonnull context) {
                [client fetchNewStories:^(NSArray<HackerNewsStory *> * _Nullable stories, NSError * _Nullable error) {
                    if (stories == nil || error != nil) {
                        NSLog(@"Got error while fetching new stories. error=%@", error);
                        completion();
                        return;
                    }
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isNew == 1"];
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publishingTime" ascending:NO];
                    [self updateStoryListWithContext:context predicate:predicate sortDescriptor:sortDescriptor newStories:stories setIsTopToYes:NO setIsNewToYes:YES];
                    
                    // Cleanup: we don't show or use stories that are neither top, new or saved
                    NSFetchRequest<NewsStory *> *fetchRequestForOldStories = [NewsStory fetchRequest];
                    fetchRequestForOldStories.predicate = [NSPredicate predicateWithFormat:@"isTop == 0 AND isNew == 0 and isSaved == 0"];
                    NSArray<NewsStory *> *oldStories = [context executeFetchRequest:fetchRequestForOldStories error:nil];
                    
                    for (NewsStory *oldStory in oldStories) {
                        [context deleteObject:oldStory];
                    }
                    
                    [self saveContext:context];
                    
                    completion();
                }];
            }];
        }];
    }];
}

-(void)updateStoryListWithContext:(NSManagedObjectContext*)context
                        predicate:(NSPredicate*)predicate
                   sortDescriptor:(NSSortDescriptor*)sortDescriptor
                       newStories:(NSArray<HackerNewsStory *> *)newStories
                       setIsTopToYes:(BOOL)isTop
                       setIsNewToYes:(BOOL)isNew {
    
    NSArray<NewsStory *> *dbStories =  [[self fetchWithPredicate:predicate sortDescriptor:sortDescriptor context:context] fetchedObjects];
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
