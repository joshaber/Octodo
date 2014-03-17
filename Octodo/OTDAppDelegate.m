//
//  OTDAppDelegate.m
//  Octodo
//
//  Created by Josh Abernathy on 2/22/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import "OTDAppDelegate.h"
#import "OTDIssuesViewController.h"
#import "OTDIssuesViewModel.h"
#import "OTDStoreClient.h"

static NSString * const OTDAppDelegateTodoRepositoryName = @"todo";

static NSString * const OTDAppDelegateToken = @"token";
static NSString * const OTDAppDelegateLogin = @"login";

@interface OTDAppDelegate ()

@property (nonatomic, readonly, strong) OTDIssuesViewController *issuesViewController;

@property (nonatomic, readonly, strong) OTDIssuesViewModel *issuesViewModel;

@property (nonatomic, readonly, strong) OTDStoreClient *storeClient;

@end

@implementation OTDAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[OCTClient setClientID:@"276833559f2fcc2fd774" clientSecret:@"9e39c09a12fab056440c6c41d31b2e60a6ba6a12"];
	OCTClient.userAgent = @"Octodo/0.1";

	NSError *error;
	FRZStore *store = [[FRZStore alloc] initWithURL:self.storeURL error:&error];
	if (store == nil) {
		NSLog(@"Error initializing store: %@", error);
		return NO;
	}

	_storeClient = [[OTDStoreClient alloc] initWithStore:store];

	RACSignal *trim = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[store transactor] trim:&error];
		if (!success) {
			[subscriber sendError:error];
		} else {
			[subscriber sendCompleted];
		}
	}];

	_issuesViewModel = [[OTDIssuesViewModel alloc] initWithStoreClient:self.storeClient];

	[[[RACSignal
		zip:@[ [self loadClient], [trim concat:[RACSignal return:nil]] ]
		reduce:^(OCTClient *client, id _) {
			self.issuesViewModel.client = client;

			return [self updateIssuesCacheWithClient:client];
		}]
		flatten]
		subscribeError:^(NSError *error) {
			NSLog(@"Error updating issues cache: %@", error);
		}];

	_issuesViewController = [[OTDIssuesViewController alloc] initWithViewModel:self.issuesViewModel];

	self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	self.window.backgroundColor = UIColor.whiteColor;

	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.issuesViewController];
	self.window.rootViewController = navigationController;

	[self.window makeKeyAndVisible];
	
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)URL sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	[OCTClient completeSignInWithCallbackURL:URL];
	return YES;
}

#pragma mark Data

- (RACSignal *)updateIssuesCacheWithClient:(OCTClient *)client {
	return [[[self
		findTodoIssues:client]
		collect]
		flattenMap:^(NSArray *issues) {
			return [self.storeClient addIssues:issues];
		}];
}

- (NSURL *)storeURL {
	NSURL *libraryURL = [NSFileManager.defaultManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].lastObject;
	return [libraryURL URLByAppendingPathComponent:@"db.frz"];
}

- (RACSignal *)findTodoIssues:(OCTClient *)client {
	return [[[[client
		fetchRepositoryWithName:OTDAppDelegateTodoRepositoryName owner:client.user.rawLogin]
		catch:^(NSError *error) {
			NSLog(@"Error finding todo repository: %@", error);
			return [RACSignal error:error];
		}]
		doNext:^(OCTRepository *repository) {
			self.issuesViewModel.repository = repository;
		}]
		flattenMap:^(OCTRepository *repository) {
			return [[client fetchOpenIssuesForRepository:repository] oct_parsedResults];
		}];
}

- (RACSignal *)loadClient {
	NSString *token = FXKeychain.defaultKeychain[OTDAppDelegateToken];
	NSString *login = FXKeychain.defaultKeychain[OTDAppDelegateLogin];
	if (token.length > 0 && login.length > 0) {
		OCTClient *client = [OCTClient authenticatedClientWithUser:[OCTUser userWithRawLogin:login server:OCTServer.dotComServer] token:token];
		return [RACSignal return:client];
	}

	return [[OCTClient
		signInToServerUsingWebBrowser:OCTServer.dotComServer scopes:OCTClientAuthorizationScopesRepository]
		doNext:^(OCTClient *client) {
			FXKeychain.defaultKeychain[OTDAppDelegateLogin] = client.user.login;
			FXKeychain.defaultKeychain[OTDAppDelegateToken] = client.token;
		}];
}

@end
