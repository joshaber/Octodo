//
//  OTDIssuesViewModel.h
//  Octodo
//
//  Created by Josh Abernathy on 2/27/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTDStoreClient;

@interface OTDIssuesViewModel : NSObject

@property (nonatomic, readonly, copy) NSArray *issues;

@property (nonatomic, readonly, strong) RACCommand *closeCommand;

@property (nonatomic, strong) OCTClient *client;

@property (nonatomic, strong) OCTRepository *repository;

- (id)initWithStoreClient:(OTDStoreClient *)storeClient;

@end
