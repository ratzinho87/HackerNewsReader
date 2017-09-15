//
//  FirstViewController.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewTopViewController.h"
#import "NewsStoryViewController.h"
#import "StoryTableViewCell.h"
#import "NewsStoriesDataSource.h"
#import "NewsStory+CoreDataClass.h"
#import "UIButton+Block.h"
#import "UITableView+NSFetchedResultsController.h"

@interface NewTopViewController () <StoryTableViewCellDelegate, NSFetchedResultsControllerDelegate>

@property (strong) NSArray<NSFetchedResultsController<NewsStory *>*> *stories;

@end

@implementation NewTopViewController

static NSString *const ShowNewsSegueIdentifier = @"ShowNewsSegue";

- (void)viewDidLoad {
    [super viewDidLoad];    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([StoryTableViewCell class]) bundle:nil] forCellReuseIdentifier:[StoryTableViewCell reuseIdentifier]];
    
    [self loadData];
    [self startRefreshData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadData {
    NewsStoriesDataSource *dataSource = [NewsStoriesDataSource sharedInstance];
    NSFetchedResultsController<NewsStory *> *topStories = [dataSource getTopStories];
    topStories.delegate = self;
    NSFetchedResultsController<NewsStory *> *newStories = [dataSource getNewStories];
    newStories.delegate = self;
    
    self.stories = [NSArray<NSFetchedResultsController<NewsStory *>*> arrayWithObjects:topStories, newStories, nil];
}

- (IBAction)refreshButtonPressed:(UIBarButtonItem *)sender {
    [self startRefreshData];
}

- (void) startRefreshData {
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    __weak typeof(self) weakSelf = self;
    [[NewsStoriesDataSource sharedInstance] updateStories:^{
        [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
        [weakSelf loadData];
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.stories.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Top Stories";
        case 1:
            return @"New Stories";
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section >= 0 && section < self.stories.count) {
        return self.stories[section].fetchedObjects.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[StoryTableViewCell reuseIdentifier] forIndexPath:indexPath];
    
    if (cell != nil) {
        cell.delegate = self;
        [cell configureWith:[self getStoryAt:indexPath]];
    }
    
    return cell;
}

-(NewsStory *)getStoryAt:(NSIndexPath *)indexPath {
    // This method helps us deal with the fact that we have two sections in the table,
    // but we are not using the sections built into NSFetchedResultsController
    return [self.stories[indexPath.section] objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
}

-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsStory *story = [self getStoryAt:indexPath];
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *saveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                          title:story.isSaved ? @"Unsave" : @"Save"
                                                                        handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                            if(weakSelf != nil) {
                                                                                typeof(self) strongSelf = weakSelf;
                                                                                NewsStory *story = [strongSelf getStoryAt:indexPath];
                                                                                if (story.isSaved) {
                                                                                    [[NewsStoriesDataSource sharedInstance] unsaveStory:story];
                                                                                } else {
                                                                                    [[NewsStoriesDataSource sharedInstance] saveStory:story];
                                                                                }
                                                                            }
                                                                        }];
    
    return [NSArray<UITableViewRowAction *> arrayWithObject:saveAction];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // This method must be implemented in order for the row swipe to work
}

-(void)didPressMarkAsReadOn:(NewsStory *)story {
    if (story.isRead) {
        [[NewsStoriesDataSource sharedInstance] markStoryAsUnread:story];
    } else {
        [[NewsStoriesDataSource sharedInstance] markStoryAsRead:story];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsStory *story = [self getStoryAt:indexPath];
    [self performSegueWithIdentifier:ShowNewsSegueIdentifier sender:story];
    
    // Don't leave the row selected, so it can be tapped again
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    /*if (type == NSFetchedResultsChangeUpdate) {
        NSIndexPath *tableIndexPath = [NSIndexPath indexPathForRow:indexPath.row
                                                         inSection:[self.stories indexOfObject:controller]];
        [self.tableView reloadRowsAtIndexPaths:[NSArray<NSIndexPath *> arrayWithObject:tableIndexPath]
                              withRowAnimation:NO];
    }*/
    
    NSIndexPath *tableIndexPath = [NSIndexPath indexPathForRow:indexPath.row
                                                     inSection:[self.stories indexOfObject:controller]];
    NSIndexPath *newTableIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row
                                                     inSection:[self.stories indexOfObject:controller]];
    [self.tableView addChangeForObjectAtIndexPath:tableIndexPath forChangeType:type newIndexPath:newTableIndexPath];
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView commitChanges];
}

 #pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier  isEqual: ShowNewsSegueIdentifier] && [sender isKindOfClass:[NewsStory class]]) {
         NewsStoryViewController *destination = [segue destinationViewController];
         destination.story = (NewsStory*)sender;
         if (!destination.story.isRead) {
             [[NewsStoriesDataSource sharedInstance] markStoryAsRead:destination.story];
         }
     }
 }

@end
