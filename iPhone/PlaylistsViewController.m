//
//  PlaylistsViewController.m
//  iVerb
//
//  Created by Max on 06/12/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "PlaylistsViewController.h"

#import "SearchViewController.h"
#import "CloudViewController.h"
#import "QuizViewController.h"

#import "ManagedObjectContext.h"

#import "Playlist+additions.h"

#define kAlertInfo 1234
#define kAlertMore 2345

@interface PlaylistsViewController ()
{
	NSIndexPath * _indexPathForActionSheet;
}
@end

@implementation PlaylistsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    self.clearsSelectionOnViewWillAppear = YES;
    
	self.title = @"Lists";
	
	CGRect frame = CGRectMake(0., 0., 23., 23.);
	UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoDark];
	button.frame = frame;
	[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
	button.tintColor = self.view.window.tintColor;
    
	UIBarButtonItem * infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.leftBarButtonItem = infoButtonItem;
    
	defaultPlaylists = [Playlist defaultPlaylists];
	
	SearchViewController * searchViewController = [[SearchViewController alloc] init];
	searchViewController.playlist = [Playlist allVerbsPlaylist];
	[self.navigationController pushViewController:searchViewController animated:NO];
	
	[self reloadData];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadData)
												 name:@"PlaylistDidUpdatedNotification"
											   object:nil];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString * title = [NSString stringWithFormat:@"iVerb %@\nCopyright © 2014, Lis@cintosh", infoDictionary[@"CFBundleShortVersionString"]];
	
	if (TARGET_IS_IPAD()) {
		UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
																  delegate:self
														 cancelButtonTitle:@"Cancel"
													destructiveButtonTitle:nil
														 otherButtonTitles: @"Feedback & Support", @"Go to my website", @"See all my application", nil];
		actionSheet.tag = kAlertInfo;
		[actionSheet showInView:self.view];
		
	} else {
		ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:@"Cancel"
												destructiveButtonTitle:nil
													 otherButtonTitles: @"Feedback & Support", @"Go to my website", @"See all my application", nil];
		actionSheet.tag = kAlertInfo;
		[actionSheet showInView:self.view];
	}
}

- (void)createNewListWithName:(NSString *)name
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Playlist"
											   inManagedObjectContext:context];
	
	NSManagedObject * playlist = [[NSManagedObject alloc] initWithEntity:entity
										  insertIntoManagedObjectContext:context];
	[playlist setValue:name forKey:@"name"];
	[playlist setValue:[NSDate date] forKey:@"creationDate"];
	
	[context save:NULL];
}

- (void)reloadData
{
	userPlaylists = [[NSArray alloc] initWithArray:[Playlist userPlaylists]];
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	[Playlist setCurrentPlaylist:nil];
}

- (void)editableCellDidBeginEditing:(EditableTableViewCell *)cell
{
	NSDebugLog(@"editableCellDidBeginEditing");
	
	[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForCell:cell]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

- (void)editableCellDidEndEditing:(EditableTableViewCell *)cell
{
	NSDebugLog(@"editableCellDidEndEditing: %@", cell.fieldValue);
	
	NSString * name = cell.fieldValue;
	if (name.length > 0) {
		[self createNewListWithName:name];
		[self reloadData];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return defaultPlaylists.count;
	} else if (section == 1) {
		return 1;
	}
	
	return userPlaylists.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	static NSString * cellID = @"CellID";
	if (indexPath.section == 0) {
		
		cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
		
		Playlist * playlist = defaultPlaylists[indexPath.row];
		cell.textLabel.text = NSLocalizedString(playlist.name, nil);
        
        cell.detailTextLabel.text = (playlist.isBookmarksPlaylist && playlist.verbs.count > 0)? [NSString stringWithFormat:@"%lu", (unsigned long)playlist.verbs.count] : @"";
		
	} else if (indexPath.section == 1) {
		
		cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
		
		cell.textLabel.text = @"Cloud";
		
	} else {
		
		if (indexPath.row > (NSInteger)(userPlaylists.count - 1)) {
			// New cell for creating
			
			static NSString * newCellID = @"NewCellID";
			cell = (EditableTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:newCellID];
			
			if (!cell) {
				cell = [[EditableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newCellID];
				((EditableTableViewCell *)cell).delegate = self;
			}
			
			((EditableTableViewCell *)cell).fieldValue = nil;
			
		} else {
			// Existing playlists
			
			static NSString * userCellID = @"UserCellID";
			cell = [aTableView dequeueReusableCellWithIdentifier:userCellID];
			
			if (!cell)
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:userCellID];
			
			Playlist * playlist = userPlaylists[indexPath.row];
			cell.textLabel.text = NSLocalizedString(playlist.name, nil);
			
			/* If the playlist is not empty, show the number of verbs */
			cell.detailTextLabel.text = (playlist.verbs.count > 0)? [NSString stringWithFormat:@"%lu", (unsigned long)playlist.verbs.count] : @"";
            
            cell.accessoryType = (playlist.verbs.count > 0) ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
	return cell;
}

#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 2;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	Playlist * playlist = userPlaylists[indexPath.row];
	
	/* Delete the playlist from Core Data */
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	[context deleteObject:playlist];
	[context save:NULL];
	
	/* Reload the TableView */
	[aTableView beginUpdates];
	[aTableView deleteRowsAtIndexPaths:@[indexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
	userPlaylists = [[NSArray alloc] initWithArray:[Playlist userPlaylists]];
	[aTableView endUpdates];
}

- (void)tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	selectedPlaylist = userPlaylists[indexPath.row];
	
	if (TARGET_IS_IPAD()) {
		_indexPathForActionSheet = indexPath;
		UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																  delegate:self
														 cancelButtonTitle:@"Cancel"
													destructiveButtonTitle:@"Delete"
														 otherButtonTitles:@"Launch the Quiz", nil];
		actionSheet.tag = kAlertMore;
        CGRect frame = [aTableView cellForRowAtIndexPath:indexPath].frame;
		CGRect newFrame = CGRectOffset(frame, 115., 7.);
		[actionSheet showFromRect:newFrame inView:self.view animated:NO];
	} else {
		ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:nil
															  delegate:self
													 cancelButtonTitle:@"Cancel"
												destructiveButtonTitle:@"Delete"
													 otherButtonTitles:@"Launch the Quiz", nil];
		actionSheet.tag = kAlertMore;
		[actionSheet showInView:self.view];
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		
		Playlist * playlist = defaultPlaylists[indexPath.row];
		[Playlist setCurrentPlaylist:playlist];
		
		SearchViewController * searchViewController = [[SearchViewController alloc] init];
		searchViewController.playlist = playlist;
		[self.navigationController pushViewController:searchViewController animated:YES];
		
	} else if (indexPath.section == 1) {
		
		CloudViewController * cloudViewController = [[CloudViewController alloc] init];
		
		if (TARGET_IS_IPAD()) {
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:cloudViewController];
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.view.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
			
			/* Deselect the cell */
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		} else {
			[self.navigationController pushViewController:cloudViewController animated:YES];
		}
		
	} else {
		if (indexPath.row <= (NSInteger)(userPlaylists.count - 1)) {
			
			Playlist * playlist = userPlaylists[indexPath.row];
			[Playlist setCurrentPlaylist:playlist];
			
			SearchViewController * searchViewController = [[SearchViewController alloc] init];
			searchViewController.playlist = playlist;
			[self.navigationController pushViewController:searchViewController animated:YES];
		} else {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
	}
}

#pragma mark -
#pragma mark ActionSheetDelegate

- (void)actionSheet:(ActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kAlertInfo) {
		switch (buttonIndex) {
			case 0:// Feedback & Support
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/iVerb/"]];
				break;
			case 1:// Go to my website
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lisacintosh.com/"]];
				break;
			case 2: {// See all my applications
				/* Link via iTunes -> AppStore, I haven't found better! */
				NSString * iTunesLink = @"https://itunes.apple.com/us/artist/lisacintosh/id320891279?uo=4";// old link = http://search.itunes.apple.com/WebObjects/MZContentLink.woa/wa/link?path=apps%2flisacintosh
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
				
				/* Link via Safari -> iTunes -> AppStore */
				//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/lisacintosh/"]];
			}
				break;
                default:// Cancel
				break;
		}
	} else if (actionSheet.tag == kAlertMore) {
		switch (buttonIndex) {
			case 0: {// "Delete"
				Playlist * playlist = userPlaylists[_indexPathForActionSheet.row];
				
				/* Delete the playlist from Core Data */
				NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
				[context deleteObject:playlist];
				[context save:NULL];
				
				/* Reload the TableView */
				[self.tableView beginUpdates];
				[self.tableView deleteRowsAtIndexPaths:@[_indexPathForActionSheet]
								  withRowAnimation:UITableViewRowAnimationFade];
				userPlaylists = [[NSArray alloc] initWithArray:[Playlist userPlaylists]];
				[self.tableView endUpdates];
				_indexPathForActionSheet = nil;
			}
				break;
			case 1: {// "Launch the Quiz"
				QuizViewController * quizViewController = [[QuizViewController alloc] init];
				quizViewController.playlist = selectedPlaylist;
				
				UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:quizViewController];
				if (TARGET_IS_IPAD()) {
					navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
				}
				
				[self presentViewController:navigationController animated:YES completion:NULL];
			}
				break;
                default:// Cancel
				break;
		}
	}
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationPortrait;
}

@end
