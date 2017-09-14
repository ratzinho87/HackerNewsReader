//
//  NewsStoryTableViewCell.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsStoryTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *publishingTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *markAsReadButton;

@end
