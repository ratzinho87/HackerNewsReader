//
//  StoryTableViewCell.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "StoryTableViewCell.h"

@implementation StoryTableViewCell

+(NSString *)reuseIdentifier {
    return @"StoryTableViewCellReuseIdentifier";
}

+(NSDateFormatter *)dateFormatter {
    static NSDateFormatter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NSDateFormatter alloc] init];
        [instance setDateStyle:NSDateFormatterMediumStyle];
        [instance setTimeStyle:NSDateFormatterMediumStyle];
    });
    return instance;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

-(void)configureWith:(NewsStory*)story at:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
    
    self.titleLabel.text = story.title;
    self.publishingTimeLabel.text = [[StoryTableViewCell dateFormatter] stringFromDate:story.publishingTime];
    
    UIImage *readImage = story.isRead ? [UIImage imageNamed:@"flag_filled"] : [UIImage imageNamed:@"flag_empty"];
    [self.markAsReadButton setImage:readImage forState:UIControlStateNormal];
}

- (IBAction)markAsReadButtonPressed:(UIButton *)sender {
    if (self.delegate != nil) {
        [self.delegate didPressMarkAsReadOn:self.indexPath];
    }
}

@end
