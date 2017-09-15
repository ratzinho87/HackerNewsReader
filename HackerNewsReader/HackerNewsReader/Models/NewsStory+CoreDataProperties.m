//
//  NewsStory+CoreDataProperties.m
//  HackerNewsReader
//
//  Created by vagrant on 15/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewsStory+CoreDataProperties.h"

@implementation NewsStory (CoreDataProperties)

+ (NSFetchRequest<NewsStory *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"NewsStory"];
}

@dynamic identifier;
@dynamic publishingTime;
@dynamic isRead;
@dynamic isSaved;
@dynamic title;
@dynamic url;
@dynamic isTop;
@dynamic isNew;
@dynamic score;

@end
