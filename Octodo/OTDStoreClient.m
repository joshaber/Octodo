//
//  OTDStoreClient.m
//  Octodo
//
//  Created by Josh Abernathy on 2/28/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import "OTDStoreClient.h"

static NSString * const OTDIssues = @"issues";

@interface OTDStoreClient ()

@property (nonatomic, readonly, strong) FRZStore *store;

@end

@implementation OTDStoreClient

- (id)initWithStore:(FRZStore *)store {
	self = [super init];
	if (self == nil) return nil;

	_store = store;

	_issues = [self.store valuesAndChangesForID:OTDIssues];

	return self;
}

#pragma mark Data

- (RACSignal *)storeIssues:(NSArray *)issues {
	FRZTransactor *transactor = [self.store transactor];
	NSError *error;
	BOOL success = [transactor performChangesWithError:&error block:^(NSError **error) {
		for (OCTIssue *issue in issues) {
			BOOL success = [transactor addValues:issue.dictionaryValue forID:issue.objectID error:error];
			if (!success) return NO;

			success = [transactor addValue:issue.objectID forKey:issue.objectID ID:OTDIssues error:error];
			if (!success) return NO;
		}

		return YES;
	}];

	if (!success) return [RACSignal error:error];

	return [RACSignal empty];
}

- (RACSignal *)deleteIssue:(OCTIssue *)issue {
	FRZTransactor *transactor = [self.store transactor];
	NSError *error;
	BOOL success = [transactor removeValue:issue.objectID forKey:issue.objectID ID:OTDIssues error:&error];
	if (!success) return [RACSignal error:error];

	return [RACSignal empty];
}

@end
