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

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureWith:(NewsStory*)story {
    self.titleLabel.text = story.title;
    self.publishingTimeLabel.text = [NSString stringWithFormat:@"%@", story.publishingTime];
    
    UIImage *readImage = story.isRead ? [UIImage imageNamed:@"flag_filled"] : [UIImage imageNamed:@"flag_empty"];
    [self.markAsReadButton setImage:readImage forState:UIControlStateNormal];
}

@end
