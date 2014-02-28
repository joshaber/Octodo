//
//  OTDIssuesViewModel.h
//  Octodo
//
//  Created by Josh Abernathy on 2/27/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTDIssuesViewModel : NSObject

@property (nonatomic, readonly, copy) NSArray *issues;

- (id)initWithIssuesFeed:(RACSignal *)issuesFeed;

@end
