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
	[RACObserve(self.viewModel, issues) subscribeNext:^(RACTuple *tuple) {
		@strongify(self);
		FRZChange *change = tuple[1];
		NSLog(@"%@", change);
		[self.tableView reloadData];
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
	return [self.viewModel.issues[0] count];
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
	[[self.viewModel.closeCommand execute:issue] subscribeNext:^(id _) {
		NSLog(@"D");
//		[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
	} error:^(NSError *error) {
		NSLog(@"Error closing %@: %@", issue, error);
	}];
}

#pragma mark Data

- (OCTIssue *)issueWithIndexPath:(NSIndexPath *)indexPath {
	return self.viewModel.issues[0][indexPath.row];
}

#pragma mark Actions

- (void)add {
	NSLog(@"LOLOLOL");
}

@end
