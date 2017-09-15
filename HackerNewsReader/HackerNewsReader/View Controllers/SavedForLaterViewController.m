//
//  SecondViewController.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "SavedForLaterViewController.h"
#import "NewsStoriesDataSource.h"
#import "StoryTableViewCell.h"
#import "NewsStoryViewController.h"

@interface SavedForLaterViewController () <StoryTableViewCellDelegate, NSFetchedResultsControllerDelegate>

@property (strong) NSFetchedResultsController<NewsStory *> *stories;

-(void)handleSavedStoriesChanged:(NSNotification*)notification;

@end

@implementation SavedForLaterViewController

static NSString *const ShowNewsSegueIdentifier = @"ShowNewsSegue";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([StoryTableViewCell class]) bundle:nil] forCellReuseIdentifier:[StoryTableViewCell reuseIdentifier]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSavedStoriesChanged:) name:SavedStoriesChangedNotification object:nil];
    
    [self loadData];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadData {
    self.stories = [[NewsStoriesDataSource sharedInstance] getSavedStories];
    self.stories.delegate = self;
}

-(void)handleSavedStoriesChanged:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadData];
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stories.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[StoryTableViewCell reuseIdentifier] forIndexPath:indexPath];
    
    if (cell != nil) {
        cell.delegate = self;
        [cell configureWith:[self.stories objectAtIndexPath:indexPath] at:indexPath];
    }
    
    return cell;
}

-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *saveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                          title:@"Unsave"
                                                                        handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                            if(weakSelf != nil) {
                                                                                typeof(self) strongSelf = weakSelf;
                                                                                [[NewsStoriesDataSource sharedInstance] unsaveStory:[strongSelf.stories objectAtIndexPath:indexPath]];
                                                                            }
                                                                        }];
    
    return [NSArray<UITableViewRowAction *> arrayWithObject:saveAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}

-(void)didPressMarkAsReadOn:(NSIndexPath *)indexPath {
    NewsStory *story = [self.stories objectAtIndexPath:indexPath];
    if (story.isRead) {
        [[NewsStoriesDataSource sharedInstance] markStoryAsUnread:story];
    } else {
        [[NewsStoriesDataSource sharedInstance] markStoryAsRead:story];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsStory *story = [self.stories objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:ShowNewsSegueIdentifier sender:story];
    
    // Don't leave the row selected, so it can be tapped again
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    if (type == NSFetchedResultsChangeUpdate) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray<NSIndexPath *> arrayWithObject:indexPath]
                              withRowAnimation:NO];
    }
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
