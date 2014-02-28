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

static NSString * const OTDAppDelegateTodoRepositoryName = @"todo";

static NSString * const OTDAppDelegateToken = @"token";
static NSString * const OTDAppDelegateLogin = @"login";

static NSString * const OTDIssues = @"issues";

@interface OTDAppDelegate ()

@property (nonatomic, readonly, strong) FRZStore *store;

@property (nonatomic, readonly, strong) OTDIssuesViewController *issuesViewController;

@end

@implementation OTDAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[OCTClient setClientID:@"276833559f2fcc2fd774" clientSecret:@"9e39c09a12fab056440c6c41d31b2e60a6ba6a12"];
	OCTClient.userAgent = @"Octodo/0.1";

	NSError *error;
	_store = [[FRZStore alloc] initWithURL:self.storeURL error:&error];
	if (self.store == nil) {
		NSLog(@"Error initializing store: %@", error);
		return NO;
	}

	RACSignal *trim = [RACSignal startLazilyWithScheduler:[RACScheduler scheduler] block:^(id<RACSubscriber> subscriber) {
		NSError *error;
		BOOL success = [[self.store transactor] trim:&error];
		if (!success) {
			[subscriber sendError:error];
		} else {
			[subscriber sendCompleted];
		}
	}];

	[[[RACSignal
		zip:@[ [self loadClient], [trim concat:[RACSignal return:nil]] ]
		reduce:^(OCTClient *client, id _) {
			return [self updateIssuesCacheWithClient:client];
		}]
		flatten]
		subscribeError:^(NSError *error) {
			NSLog(@"Error updating issues cache: %@", error);
		}];

	RACSignal *issues = [self.store valuesAndChangesForID:OTDIssues];
	OTDIssuesViewModel *viewModel = [[OTDIssuesViewModel alloc] initWithIssuesFeed:issues];
	_issuesViewController = [[OTDIssuesViewController alloc] initWithViewModel:viewModel];

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
		}];
}

- (NSURL *)storeURL {
	NSURL *libraryURL = [NSFileManager.defaultManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].lastObject;
	return [libraryURL URLByAppendingPathComponent:@"db.frz"];
}

- (RACSignal *)findTodoIssues:(OCTClient *)client {
	return [[[client
		fetchRepositoryWithName:OTDAppDelegateTodoRepositoryName owner:client.user.rawLogin]
		catch:^(NSError *error) {
			NSLog(@"Error finding todo repository: %@", error);
			return [RACSignal error:error];
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
