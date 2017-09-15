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

@interface NewTopViewController () <StoryTableViewCellDelegate>

@property (strong) NSArray<NSArray<NewsStory *>*> *stories;

@end

@implementation NewTopViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    [self.tableView registerNib:[UINib nibWithNibName:@"StoryTableViewCell" bundle:nil] forCellReuseIdentifier:[StoryTableViewCell reuseIdentifier]];
    
    [self loadData];
    [self startRefreshData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadData {
    NewsStoriesDataSource *dataSource = [NewsStoriesDataSource sharedInstance];
    
    NSMutableArray<NSArray<NewsStory *>*> *stories = [NSMutableArray<NSArray<NewsStory *>*> array];
    
    NSArray<NewsStory *>* top = [dataSource getTopStories];
    if (top != nil) {
        [stories addObject:top];
    } else {
        [stories addObject:[NSArray<NewsStory *> array]];
    }
    
    NSArray<NewsStory *>* new = [dataSource getNewStories];
    if (new != nil) {
        [stories addObject:new];
    } else {
        [stories addObject:[NSArray<NewsStory *> array]];
    }
    self.stories = stories;
}

- (IBAction)refreshButtonPressed:(UIBarButtonItem *)sender {
    [self startRefreshData];
}

- (void) startRefreshData {
    __weak typeof(self) weakSelf = self;
    [[NewsStoriesDataSource sharedInstance] updateStories:^{
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
        return self.stories[section].count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[StoryTableViewCell reuseIdentifier] forIndexPath:indexPath];
    
    if (cell != nil) {
        cell.delegate = self;
        [cell configureWith:self.stories[indexPath.section][indexPath.row] at:indexPath];
    }
    
    return cell;
}

-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsStory *story = self.stories[indexPath.section][indexPath.row];
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *saveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                          title:story.isSaved ? @"Unsave" : @"Save"
                                                                        handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                            if(weakSelf != nil) {
                                                                                typeof(self) strongSelf = weakSelf;
                                                                                NewsStory *story = strongSelf.stories[indexPath.section][indexPath.row];
                                                                                if (story.isSaved) {
                                                                                    [[NewsStoriesDataSource sharedInstance] unsaveStory:story];
                                                                                } else {
                                                                                    [[NewsStoriesDataSource sharedInstance] saveStory:story];
                                                                                }
                                                                                
                                                                                [strongSelf.tableView reloadRowsAtIndexPaths:[NSArray<NSIndexPath *> arrayWithObject:indexPath]
                                                                                                            withRowAnimation:YES];
                                                                            }
                                                                        }];
    
    return [NSArray<UITableViewRowAction *> arrayWithObject:saveAction];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // This method must be implemented in order for the row swipe to work
}

-(void)didPressMarkAsReadOn:(NSIndexPath *)indexPath {
    NewsStory *story = self.stories[indexPath.section][indexPath.row];
    if (story.isRead) {
        [[NewsStoriesDataSource sharedInstance] markStoryAsUnread:story];
    } else {
        [[NewsStoriesDataSource sharedInstance] markStoryAsRead:story];
    }
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray<NSIndexPath *> arrayWithObject:indexPath]
                                withRowAnimation:NO];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsStory *story = self.stories[indexPath.section][indexPath.row];
    [self performSegueWithIdentifier:@"ShowNewsSegue" sender:story];
    
    // Don't leave the row selected, so it can be tapped again
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


 #pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier  isEqual: @"ShowNewsSegue"] && [sender isKindOfClass:[NewsStory class]]) {
         NewsStoryViewController *destination = [segue destinationViewController];
         destination.story = (NewsStory*)sender;
         if (!destination.story.isRead) {
             [[NewsStoriesDataSource sharedInstance] markStoryAsRead:destination.story];
         }
     }
 }

@end
