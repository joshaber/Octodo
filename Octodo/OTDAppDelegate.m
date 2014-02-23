//
//  OTDAppDelegate.m
//  Octodo
//
//  Created by Josh Abernathy on 2/22/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import "OTDAppDelegate.h"

@implementation OTDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[OCTClient setClientID:@"276833559f2fcc2fd774" clientSecret:@"9e39c09a12fab056440c6c41d31b2e60a6ba6a12"];
	OCTClient.userAgent = @"Octodo/0.1";

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    [self.window makeKeyAndVisible];

	[[OCTClient signInToServerUsingWebBrowser:OCTServer.dotComServer scopes:OCTClientAuthorizationScopesRepository] subscribeNext:^(id x) {
		NSLog(@"%@", x);
	}];
	
    return YES;
}

@end
