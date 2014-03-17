//
//  OTDIssuesViewModel.m
//  Octodo
//
//  Created by Josh Abernathy on 2/27/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import "OTDIssuesViewModel.h"
#import "OTDStoreClient.h"

@interface OTDIssuesViewModel ()

@property (nonatomic, readonly, strong) OTDStoreClient *storeClient;

@property (nonatomic, readonly, strong) OCTIssue *issue;

@end

@implementation OTDIssuesViewModel

- (id)initWithStoreClient:(OTDStoreClient *)storeClient {
	NSParameterAssert(storeClient != nil);

	self = [super init];
	if (self == nil) return nil;

	_storeClient = storeClient;

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
		return [[self.storeClient
			deleteIssue:issue]
			then:^{
				return [RACSignal empty];
				return [[[self.client
					postComment:@":boom:" forIssue:issue inRepository:self.repository]
					then:^{
						return [self.client closeIssue:issue inRepository:self.repository];
					}]
					doError:^(NSError *error) {
						[self.storeClient addIssues:@[ issue ]];
					}];
			}];
	}];

	RAC(self, issues) = [[self.storeClient.issues
		map:^(NSArray *changes) {
			return [[changes.rac_sequence
				reduceEach:^(NSDictionary *values, FRZChange *change) {
					NSArray *vs = [[values.rac_keySequence
						map:^(NSString *key) {
							NSDictionary *info = change.changedDatabase[key];
							return [[OCTIssue alloc] initWithDictionary:info error:NULL];
						}]
						array];

					return RACTuplePack(vs, change);
				}]
				array];
		}]
		deliverOn:RACScheduler.mainThreadScheduler];

	return self;
}

@end
