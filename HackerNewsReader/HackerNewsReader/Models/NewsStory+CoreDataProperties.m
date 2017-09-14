//
//  NewsStory+CoreDataProperties.m
//  HackerNewsReader
//
//  Created by vagrant on 14/09/2017.
//  Copyright © 2017 cvlad. All rights reserved.
//

#import "NewsStory+CoreDataProperties.h"

@implementation NewsStory (CoreDataProperties)

+ (NSFetchRequest<NewsStory *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"NewsStory"];
}

@dynamic identifier;
@dynamic title;
@dynamic publishingTime;
@dynamic read;
@dynamic saved;
@dynamic url;

@end
