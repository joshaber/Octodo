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

@property (nonatomic, readonly, strong) OCTIssue *issue;

@end

@implementation OTDIssuesViewModel

- (id)initWithIssuesFeed:(RACSignal *)issuesFeed {
	NSParameterAssert(issuesFeed != nil);

	self = [super init];
	if (self == nil) return nil;

	_issuesFeed = issuesFeed;

	RACSignal *haveClient = [RACObserve(self, client) map:^(OCTClient *client) {
		return @(client != nil);
	}];

	RACSignal *haveRepository = [RACObserve(self, repository) map:^(OCTRepository *repository) {
		return @(repository != nil);
	}];

	RACSignal *enabled = [RACSignal combineLatest:@[ haveClient, haveRepository ] reduce:^(NSNumber *haveClient, NSNumber *haveRepository) {
		return @(haveClient.boolValue && haveRepository.boolValue);
	}];

	@weakify(self);
	_closeCommand = [[RACCommand alloc] initWithEnabled:enabled signalBlock:^(OCTIssue *issue) {
		@strongify(self);
		return [[self.client
			postComment:@":boom:" forIssue:issue inRepository:self.repository]
			then:^{
				return [self.client closeIssue:issue inRepository:self.repository];
			}];
	}];

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
