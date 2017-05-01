//
//  VerbOptionsViewController.m
//  iVerb
//
//  Created by Max on 06/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "VerbOptionsViewController.h"

#import "ManagedObjectContext.h"
#import "Playlist+additions.h"
#import "UIColor+addition.h"

@interface VerbOptionsViewController ()

@property (nonatomic, strong) NSArray * userPlaylists;

@end

@implementation VerbOptionsViewController

- (instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) { }
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Add to list";
    self.navigationController.navigationBar.tintColor = [UIColor foregroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(doneAction:)];
	_userPlaylists = [Playlist userPlaylists];
}

- (IBAction)doneAction:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ResultsDidChangeNotification object:nil];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger count = _userPlaylists.count;
	return 1 /* Bookmarks */ + (count > 0);
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	
	return _userPlaylists.count;
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
		cell.accessoryType = (allBookmarked) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		
	} else {
		Playlist * playlist = _userPlaylists[indexPath.row];
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	
	if (indexPath.section == 0) {
		
		BOOL allBookmarked = YES;
		for (Verb * verb in _verbs) {
			allBookmarked &= verb.isBookmarked;
			if (!allBookmarked) break;
		}
		
		if (allBookmarked)
			for (Verb * verb in _verbs) [[Playlist bookmarksPlaylist] removeVerb:verb];
		else
			for (Verb * verb in _verbs) [[Playlist bookmarksPlaylist] addVerb:verb];
		
	} else {
		Playlist * playlist = _userPlaylists[indexPath.row];
		
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
			for (Verb * verb in _verbs) [playlist removeVerb:verb];
		else
			for (Verb * verb in _verbs) [playlist addVerb:verb];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistDidUpdatedNotification object:playlist];
	}
	
	if (cell.accessoryType == UITableViewCellAccessoryNone)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (_userPlaylists.count == 0) // Only bookmarks...
		[self doneAction:nil]; // ... dismiss controller
}

@end
