//
//  OTDIssuesViewController.m
//  Octodo
//
//  Created by Josh Abernathy on 2/27/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

#import "OTDIssuesViewController.h"
#import "OTDIssuesViewModel.h"

@interface OTDIssuesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly, strong) OTDIssuesViewModel *viewModel;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation OTDIssuesViewController

#pragma mark Lifecycle

- (id)initWithViewModel:(OTDIssuesViewModel *)viewModel {
	NSParameterAssert(viewModel != nil);

	self = [super init];
	if (self == nil) return nil;

	_viewModel = viewModel;

	@weakify(self);
	[[RACObserve(self.viewModel, issues) combinePreviousWithStart:nil reduce:^ id (NSArray *previous, NSArray *next) {
		if (previous == nil) {
			return ^(UITableView *tableView) {
				[tableView reloadData];
			};
		}

		NSMutableArray *adds = [NSMutableArray array];
		NSMutableArray *deletes = [NSMutableArray array];
		NSMutableArray *reloads = [NSMutableArray array];
		for (RACTuple *tuple in next) {
			RACTupleUnpack(NSArray *newIssues, FRZChange *change) = tuple;
			NSArray *oldIssues = previous.lastObject[0];
			id filterBlock = ^(OCTIssue *issue, NSUInteger idx, BOOL *stop) {
				return [issue.objectID isEqual:change.key];
			};
			NSUInteger newIndex = [newIssues indexOfObjectPassingTest:filterBlock];
			NSUInteger oldIndex = [oldIssues indexOfObjectPassingTest:filterBlock];

			if (change.type == FRZChangeTypeAdd) {
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
				if (oldIndex == newIndex) {
					[reloads addObject:indexPath];
				} else {
					[adds addObject:indexPath];
				}
			} else {
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:oldIndex inSection:0];
				[deletes addObject:indexPath];
			}
		}

		return ^(UITableView *tableView) {
			[tableView beginUpdates];

			[tableView insertRowsAtIndexPaths:adds withRowAnimation:UITableViewRowAnimationAutomatic];
			[tableView deleteRowsAtIndexPaths:deletes withRowAnimation:UITableViewRowAnimationAutomatic];
			[tableView reloadRowsAtIndexPaths:reloads withRowAnimation:UITableViewRowAnimationAutomatic];

			[tableView endUpdates];
		};
	}] subscribeNext:^(void (^action)(UITableView *)) {
		@strongify(self);
		if (action != NULL) {
			action(self.tableView);
		}
	}];

	return self;
}

#pragma mark UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.title = NSLocalizedString(@"Todo", @"");
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Close", @"");
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.orderedIssues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString * const CellIdentifier = @"CellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.numberOfLines = 2;
	}

	OCTIssue *issue = [self issueWithIndexPath:indexPath];
	cell.textLabel.text = issue.title;

	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	OCTIssue *issue = [self issueWithIndexPath:indexPath];
	[[self.viewModel.closeCommand execute:issue] subscribeError:^(NSError *error) {
		NSLog(@"Error closing %@: %@", issue, error);
	}];
}

#pragma mark Data

- (NSArray *)orderedIssues {
	RACTuple *mostRecent = self.viewModel.issues.lastObject;
	return mostRecent[0];
}

- (OCTIssue *)issueWithIndexPath:(NSIndexPath *)indexPath {
	return self.orderedIssues[indexPath.row];
}

#pragma mark Actions

- (void)add {
	NSLog(@"LOLOLOL");
}

@end
