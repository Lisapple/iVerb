//
//  VerbOptionsViewController.m
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "VerbOptionsViewController_Phone.h"

#import "ManagedObjectContext.h"
#import "Playlist+additions.h"

@implementation VerbOptionsViewController_Phone

@synthesize tableView = _tableView;
@synthesize headerLabel = _headerLabel, headerView = _headerView;

@synthesize verbs = _verbs;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Add to list";
    self.navigationController.navigationBar.tintColor = [UIColor purpleColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self action:@selector(doneAction:)];
	userPlaylists = [Playlist userPlaylists];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.tableView reloadData]; // Reload the tableView to get the size
	
	/* Update the label at the top of the tableView with "Verb lists to add "Verb":" or "Verb lists to add these {dd} verbs:" */
	if (_verbs.count == 1) {
		Verb * verb = _verbs.firstObject;
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add \"%@\":", verb.infinitif.capitalizedString];
	} else if (_verbs.count > 1) {
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add these %lu verbs:", (unsigned long)_verbs.count];
	}
	
	[self.tableView reloadData];// Re-reload the tableView to update cells
}

- (void)setVerbs:(NSArray *)verbs
{
	_verbs = verbs;
	
	/* Update the label at the top of the tableView with "Verb lists to add "Verb":" or "Verb lists to add these {dd} verbs:" */
	if (_verbs.count == 1) {
		Verb * verb = _verbs.firstObject;
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add \"%@\":", verb.infinitif.capitalizedString];
	} else if (_verbs.count > 1) {
		_headerLabel.text = [NSString stringWithFormat:@"Verb lists to add these %lu verbs:", (unsigned long)_verbs.count];
	}
}

- (IBAction)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger count = userPlaylists.count;
	return 1 /* Bookmarks */ + (count > 0);
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
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	if (indexPath.section == 0) {
		cell.textLabel.text = [Playlist bookmarksPlaylist].localizedName;
		
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
}

@end
