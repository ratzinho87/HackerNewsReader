//
//  NewsStoryViewController.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewsStoryViewController.h"
#import "NewsStoriesDataSource.h"

@interface NewsStoryViewController ()

@property (weak, nonatomic) IBOutlet UITextField *uriTextField;
@property (weak, nonatomic) IBOutlet UIWebView *newsStoryWebView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end

@implementation NewsStoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.story.title;
    self.uriTextField.text = self.story.url;
    [self.newsStoryWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.story.url]]];
    self.saveButton.enabled = !self.story.isSaved;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(UIBarButtonItem *)sender {
    [[NewsStoriesDataSource sharedInstance] saveStory:self.story];
    // TODO: show popup?
    self.saveButton.enabled = NO;
}


@end
