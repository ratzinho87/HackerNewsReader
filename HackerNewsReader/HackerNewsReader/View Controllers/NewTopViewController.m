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

@interface NewTopViewController ()

@property (strong) NSArray<NSArray<NewsStory *>*> *stories;

@end

@implementation NewTopViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadData];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"StoryTableViewCell" bundle:nil] forCellReuseIdentifier:[StoryTableViewCell reuseIdentifier]];
    
    self.clearsSelectionOnViewWillAppear = YES;
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
    
    [dataSource updateStories:nil];
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
        [cell configureWith:self.stories[indexPath.section][indexPath.row]];
    }
    
    return cell;
}

//-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//}

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
     }
 }

@end
