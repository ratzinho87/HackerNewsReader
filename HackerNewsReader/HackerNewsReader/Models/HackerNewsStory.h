//
//  HackerNewsStory.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HackerNewsStory : NSObject

@property (nullable, nonatomic, strong) NSString *by;
@property (nullable, nonatomic, strong) NSString *identifier;
@property (nullable, nonatomic, strong) NSNumber *score;
@property (nullable, nonatomic, strong) NSDate *time;
@property (nullable, nonatomic, strong) NSString *title;
@property (nullable, nonatomic, strong) NSString *type;
@property (nullable, nonatomic, strong) NSString *url;

@end
