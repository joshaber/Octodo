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
	[RACObserve(self.viewModel, issues) subscribeNext:^(id _) {
		@strongify(self);
		[self.tableView reloadData];
	}];

	return self;
}

#pragma mark UIViewController

- (NSString *)title {
	return NSLocalizedString(@"Todos", @"");
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.viewModel.issues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString * const CellIdentifier = @"CellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

	OCTIssue *issue = [self issueWithIndexPath:indexPath];
	cell.textLabel.text = issue.title;

	return cell;
}

#pragma mark Data

- (OCTIssue *)issueWithIndexPath:(NSIndexPath *)indexPath {
	return self.viewModel.issues[indexPath.row];
}

@end
