//
//  OTDStoreClient.h
//  Octodo
//
//  Created by Josh Abernathy on 2/28/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTDStoreClient : NSObject

@property (nonatomic, readonly, strong) RACSignal *issues;

- (id)initWithStore:(FRZStore *)store;

- (RACSignal *)storeIssues:(NSArray *)issues;

- (RACSignal *)deleteIssue:(OCTIssue *)issue;

@end
