//
//  VerbOptionsViewController_Pad.m
//  iVerb
//
//  Created by Max on 08/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "VerbOptionsViewController_Pad.h"

#import "ManagedObjectContext.h"

@implementation VerbOptionsViewController_Pad

@synthesize tableView = _tableView;

@synthesize verbs = _verbs;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	userPlaylists = [Playlist userPlaylists];
	
	self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:0.85];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.tableView reloadData];
	
	self.tableView.tintColor = [UIColor whiteColor];
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
	UITableViewCell * cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.backgroundColor = [UIColor blackColor];
		cell.textLabel.highlightedTextColor = [UIColor blackColor];
	}
	
	if (indexPath.section == 0) {
		
		cell.textLabel.text = NSLocalizedString([Playlist bookmarksPlaylist].name, nil);
		
		BOOL allBookmarked = YES;
		for (Verb * verb in _verbs) { allBookmarked &= verb.isBookmarked; if (!allBookmarked) break; }
		cell.accessoryType = (allBookmarked)? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
		
	} else {
		Playlist * playlist = userPlaylists[indexPath.row];
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
		Playlist * playlist = userPlaylists[indexPath.row];
		
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

- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

@end
