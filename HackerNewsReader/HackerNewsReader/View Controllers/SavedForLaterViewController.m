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

@interface SavedForLaterViewController () <StoryTableViewCellDelegate>

@property (strong) NSArray<NewsStory *> *stories;

@end

@implementation SavedForLaterViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"StoryTableViewCell" bundle:nil] forCellReuseIdentifier:[StoryTableViewCell reuseIdentifier]];
    
    [self loadData];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadData {
    self.stories = [[NewsStoriesDataSource sharedInstance] getSavedStories];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.stories.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[StoryTableViewCell reuseIdentifier] forIndexPath:indexPath];
    
    if (cell != nil) {
        cell.delegate = self;
        [cell configureWith:self.stories[indexPath.row] at:indexPath];
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
                                                                                [[NewsStoriesDataSource sharedInstance] unsaveStory:strongSelf.stories[indexPath.row]];
                                                                                
                                                                                // Remove from the collection
                                                                                NSMutableArray<NewsStory *> *newStories = [self.stories mutableCopy];
                                                                                [newStories removeObjectAtIndex:indexPath.row];
                                                                                self.stories = newStories;
                                                                                
                                                                                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                                                            }
                                                                        }];
    
    return [NSArray<UITableViewRowAction *> arrayWithObject:saveAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}

-(void)didPressMarkAsReadOn:(NSIndexPath *)indexPath {
    NewsStory *story = self.stories[indexPath.row];
    if (story.isRead) {
        [[NewsStoriesDataSource sharedInstance] markStoryAsUnread:story];
    } else {
        [[NewsStoriesDataSource sharedInstance] markStoryAsRead:story];
    }
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray<NSIndexPath *> arrayWithObject:indexPath]
                          withRowAnimation:NO];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsStory *story = self.stories[indexPath.row];
    [self performSegueWithIdentifier:@"ShowNewsSegue" sender:story];
    
    // Don't leave the row selected, so it can be tapped again
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"ShowNewsSegue"] && [sender isKindOfClass:[NewsStory class]]) {
        NewsStoryViewController *destination = [segue destinationViewController];
        destination.story = (NewsStory*)sender;
    }
}

@end
