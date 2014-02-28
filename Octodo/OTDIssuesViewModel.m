//
//  OTDIssuesViewModel.m
//  Octodo
//
//  Created by Josh Abernathy on 2/27/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import "OTDIssuesViewModel.h"

@interface OTDIssuesViewModel ()

@property (nonatomic, readonly, strong) RACSignal *issuesFeed;

@end

@implementation OTDIssuesViewModel

- (id)initWithIssuesFeed:(RACSignal *)issuesFeed {
	NSParameterAssert(issuesFeed != nil);

	self = [super init];
	if (self == nil) return nil;

	_issuesFeed = issuesFeed;

	RAC(self, issues) = [[self.issuesFeed
		reduceEach:^(NSDictionary *values, FRZChange *change) {
			return [[values.rac_keySequence
				map:^(NSString *key) {
					NSDictionary *info = change.changedDatabase[key];
					return [[OCTIssue alloc] initWithDictionary:info error:NULL];
				}]
				array];
		}]
		deliverOn:RACScheduler.mainThreadScheduler];

	return self;
}

@end
