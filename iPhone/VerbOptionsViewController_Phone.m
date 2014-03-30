//
//  VerbOptionsViewController.m
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "VerbOptionsViewController_Phone.h"

#import "ManagedObjectContext.h"

#import "CheckTableViewCell.h"

@implementation VerbOptionsViewController_Phone

@synthesize tableView = _tableView;
@synthesize headerLabel = _headerLabel, headerView = _headerView;

@synthesize verbs = _verbs;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	userPlaylists = [Playlist userPlaylists];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.tableView reloadData];// Reload the tableView to get the size
	
	self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.tableView.tableHeaderView = _headerView;
	
	CGFloat tableViewHeight = self.tableView.contentSize.height;
	if (tableViewHeight > 400.) tableViewHeight = 400.;// Clip to 400px height
	
	CGFloat topMargin = self.view.frame.size.height - tableViewHeight;
	self.tableView.contentInset = UIEdgeInsetsMake(100., 0., 0., 0.);
	
	CGRect frame = self.tableView.frame;
	frame.origin.y = topMargin - 100.;
	frame.size.height = tableViewHeight + 100.;
	self.tableView.frame = frame;
	
	/* Update the label at the top of the tableView with "Verb lists to add "Verb":" or "Verb lists to add these {dd} verbs:" */
	if (_verbs.count == 1) {
		Verb * verb = [_verbs objectAtIndex:0];
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add \"%@\":", [verb.infinitif capitalizedString]];
	} else if (_verbs.count > 1) {
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add these %ld verbs:", (unsigned long)_verbs.count];
	}
	
	/*
	NSMutableArray * verbPlaylistsCopy = [[[self.verb mutableSetValueForKey:@"playlists"] allObjects] mutableCopy];
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	[verbPlaylistsCopy sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	verbPlaylists = (NSArray *)verbPlaylistsCopy;
	*/
	
	[self.tableView reloadData];// Re-reload the tableView to update cells
}

- (void)setVerbs:(NSArray *)verbs
{
	_verbs = verbs;
	
	/* Update the label at the top of the tableView with "Verb lists to add "Verb":" or "Verb lists to add these {dd} verbs:" */
	if (_verbs.count == 1) {
		Verb * verb = [_verbs objectAtIndex:0];
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add \"%@\":", [verb.infinitif capitalizedString]];
	} else if (_verbs.count > 1) {
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add these %ld verbs:", (unsigned long)_verbs.count];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger count = userPlaylists.count;
	return (count > 0)? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	
	return userPlaylists.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellID = @"cellID";
	CheckTableViewCell * cell = (CheckTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:cellID];
	
	if (!cell) {
		cell = [[CheckTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}
	
	cell.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.];
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	cell.textLabel.textColor = [UIColor whiteColor];
	
	if (indexPath.section == 0) {
		
		cell.textLabel.text = NSLocalizedString([Playlist bookmarksPlaylist].name, nil);
		
		BOOL allBookmarked = YES;
		for (Verb * verb in _verbs) { allBookmarked &= verb.isBookmarked; if (!allBookmarked) break; }
		cell.accessoryType = (allBookmarked)? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
		
	} else {
		Playlist * playlist = [userPlaylists objectAtIndex:indexPath.row];
		cell.textLabel.text = playlist.name;
		
		BOOL containsAllVerbs = YES;
		for (Verb * verb in _verbs) {
			NSMutableSet * playlistsName = [verb mutableSetValueForKeyPath:@"playlists.name"];
			containsAllVerbs &= ([playlistsName containsObject:playlist.name]);
			if (!containsAllVerbs) break;
		}
		cell.accessoryType = (containsAllVerbs)? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
	}
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	
	if (indexPath.section == 0) {
		
		BOOL allBookmarked = YES;
		for (Verb * verb in _verbs) { allBookmarked &= verb.isBookmarked; if (!allBookmarked) break; }
		
		if (allBookmarked)
			for (Verb * verb in _verbs) { [verb removePlaylist:[Playlist bookmarksPlaylist]]; }
		else
			for (Verb * verb in _verbs) { [verb addToPlaylist:[Playlist bookmarksPlaylist]]; }
		
	} else {
		Playlist * playlist = [userPlaylists objectAtIndex:indexPath.row];
		
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
			for (Verb * verb in _verbs) { [verb removePlaylist:playlist]; }
		else
			for (Verb * verb in _verbs) { [verb addToPlaylist:playlist]; }
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PlaylistDidUpdatedNotification" object:playlist];
	}
	
	if (cell.accessoryType == UITableViewCellAccessoryNone)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
