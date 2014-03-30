//
//  VerbOptionsViewController_Pad.m
//  iVerb
//
//  Created by Max on 08/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "VerbOptionsViewController_Pad.h"

#import "ManagedObjectContext.h"

#import "CheckTableViewCell.h"

@implementation VerbOptionsViewController_Pad

@synthesize tableView = _tableView;

@synthesize verbs = _verbs;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	userPlaylists = [Playlist userPlaylists];
	
	self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	self.tableView.backgroundView.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	
	self.tableView.backgroundView.alpha = 0.;
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.tableView reloadData];
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
		cell = [[CheckTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];// @TODO: create a class with MyTableViewCell and CheckTableViewCell
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
	
	/* Send a notification for PlaylistViewController and SearchViewController to reload tableViews */
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PlaylistDidUpdatedNotification" object:nil];
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
	return (UIDeviceOrientationIsPortrait(interfaceOrientation) || UIDeviceOrientationIsLandscape(interfaceOrientation));
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

@end
