//
//  NewsStory+CoreDataProperties.h
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewsStory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NewsStory (CoreDataProperties)

+ (NSFetchRequest<NewsStory *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *identifier;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSDate *publishingTime;
@property (nonatomic) BOOL read;
@property (nonatomic) BOOL saved;
@property (nullable, nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END
