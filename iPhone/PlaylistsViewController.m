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
#import "AProposViewController.h"

#import "ManagedObjectContext.h"

#import "Playlist+additions.h"
#import "NSDate+addition.h"
#import "UIApplication+addition.h"
#import "UIColor+addition.h"

const NSUInteger kRenamingTextFieldTag = 'rtft';

@interface TableViewCell : UITableViewCell

+ (NSString *)identifier;

@end

@implementation TableViewCell

+ (NSString *)identifier
{
	return @"CellID";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	return self;
}

@end


@interface PlaylistsViewController ()

@property (nonatomic, weak, nullable) UIAlertAction * renameAlertDefaultAction;
@property (nonatomic, strong) NSIndexPath * indexPathForActionSheet;
@property (nonatomic, strong) Playlist * selectedPlaylist;

@end

@implementation PlaylistsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    self.clearsSelectionOnViewWillAppear = YES;
    
	self.title = @"Lists";
	
	defaultPlaylists = [Playlist defaultPlaylists];
	
	[self.tableView registerClass:TableViewCell.class forCellReuseIdentifier:TableViewCell.identifier];
	
	[self reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData)
												 name:PlaylistDidUpdatedNotification object:nil];
}

- (void)createNewListWithName:(NSString *)name
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	[Playlist insertPlaylistWithName:name inManagedObjectContext:context];
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
	[[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * notification) {
		UITextField * sender = (UITextField *)notification.object;
		if (sender.tag == kRenamingTextFieldTag)
			self.renameAlertDefaultAction.enabled = (sender.text.length > 0);
	}];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	[Playlist setPlaylist:nil forAction:PlaylistActionSelect];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

#pragma mark - Editable table view cell delegate

- (void)editableCellDidBeginEditing:(EditableTableViewCell *)cell
{
	[self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForCell:cell]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

- (void)editableCellDidEndEditing:(EditableTableViewCell *)cell
{
	NSString * name = cell.fieldValue;
	if (name.length > 0) {
		[self createNewListWithName:name];
		[self reloadData];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4; // Default playlists, cloud, user playlists and about
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if /**/ (section == 0) // Default lists
		return defaultPlaylists.count;
	else if (section == 2) // User lists
		return userPlaylists.count + 1;
	
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	if (indexPath.section == 0) { // Default lists
		cell = [aTableView dequeueReusableCellWithIdentifier:TableViewCell.identifier forIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		Playlist * playlist = defaultPlaylists[indexPath.row];
		cell.textLabel.text = playlist.localizedName;
        
        cell.detailTextLabel.text = (playlist.isBookmarksPlaylist && playlist.verbs.count > 0) ? [NSString stringWithFormat:@"%lu", (unsigned long)playlist.verbs.count] : nil;
		
	} else if (indexPath.section == 1) { // Cloud
		cell = [aTableView dequeueReusableCellWithIdentifier:TableViewCell.identifier forIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.text = @"Cloud";
		
	} else if (indexPath.section == 2) { // User lists
		if (indexPath.row > (NSInteger)(userPlaylists.count - 1)) { // Cell to create a new playlist
			static NSString * newCellID = @"NewCellID";
			cell = (EditableTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:newCellID];
			if (!cell) {
				cell = [[EditableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newCellID];
				((EditableTableViewCell *)cell).delegate = self;
			}
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			((EditableTableViewCell *)cell).fieldValue = nil;
			
		} else { // Existing user lists
			cell = [aTableView dequeueReusableCellWithIdentifier:TableViewCell.identifier forIndexPath:indexPath];
			
			Playlist * playlist = userPlaylists[indexPath.row];
			cell.textLabel.text = playlist.localizedName;
			
			// If the playlist is not empty, show the number of verbs
			cell.detailTextLabel.text = (playlist.verbs.count > 0)? [NSString stringWithFormat:@"%lu", (unsigned long)playlist.verbs.count] : nil;
            
            cell.accessoryType = (playlist.verbs.count > 0) ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryDisclosureIndicator;
		}
	} else {
		cell = [aTableView dequeueReusableCellWithIdentifier:TableViewCell.identifier forIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text = @"About...";
		cell.detailTextLabel.text = nil;
	}
	
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
	return cell;
}

#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 2 && indexPath.row < userPlaylists.count); // User playlist section but not the last cell (create new list)
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	Playlist * playlist = userPlaylists[indexPath.row];
	[self deletePlaylist:playlist];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
		_selectedPlaylist = userPlaylists[indexPath.row];
        NSMutableArray * actions = @[ [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete"
                                                                       handler:^(UITableViewRowAction * action, NSIndexPath * indexPath) {
                                                                           [self deletePlaylist:_selectedPlaylist]; }] ].mutableCopy;
		if (_selectedPlaylist.verbs.count > 0) {
			UITableViewRowAction * rowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Quiz"
																				handler:^(UITableViewRowAction * action, NSIndexPath * indexPath) {
																					[self launchQuizForPlaylist:_selectedPlaylist]; }];
			rowAction.backgroundColor = [UIColor foregroundColor];
			[actions addObject:rowAction];
		}
        return actions;
    }
    return nil;
}

- (void)tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	_selectedPlaylist = userPlaylists[indexPath.row];
	
	UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil message:nil
																	   preferredStyle:UIAlertControllerStyleActionSheet];
	if (_selectedPlaylist.verbs.count > 0) {
		[alertController addAction:[UIAlertAction actionWithTitle:@"Launch the Quiz" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			[self launchQuizForPlaylist:_selectedPlaylist]; }]];
	}
	[alertController addAction:[UIAlertAction actionWithTitle:@"Rename..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[self renamePlaylist:_selectedPlaylist]; }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
		[self deletePlaylist:_selectedPlaylist]; }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
	
	if (TARGET_IS_IPAD()) {
		_indexPathForActionSheet = indexPath;
		CGRect frame = [aTableView cellForRowAtIndexPath:indexPath].frame;
		alertController.modalPresentationStyle = UIModalPresentationPopover;
		UIPopoverPresentationController * popController = alertController.popoverPresentationController;
		popController.sourceView = self.view;
		popController.sourceRect = CGRectOffset(frame, 115., 7.);
	}
	[self presentViewController:alertController animated:YES completion:NULL];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		Playlist * playlist = defaultPlaylists[indexPath.row];
		[Playlist setPlaylist:playlist forAction:PlaylistActionSelect];
		
		SearchViewController * searchViewController = [[SearchViewController alloc] init];
		searchViewController.playlist = playlist;
		[self.navigationController pushViewController:searchViewController animated:YES];
		
	} else if (indexPath.section == 1) {
		CloudViewController * cloudViewController = [[CloudViewController alloc] init];
		if (TARGET_IS_IPAD()) {
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:cloudViewController];
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.view.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
			
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES]; // Deselect the cell
		} else
			[self.navigationController pushViewController:cloudViewController animated:YES];
		
	} else if (indexPath.section == 2) {
		if (indexPath.row <= (NSInteger)(userPlaylists.count - 1)) {
			Playlist * playlist = userPlaylists[indexPath.row];
			[Playlist setPlaylist:playlist forAction:PlaylistActionSelect];
			
			SearchViewController * searchViewController = [[SearchViewController alloc] init];
			searchViewController.playlist = playlist;
			[self.navigationController pushViewController:searchViewController animated:YES];
			
		} else { // new playlist
			EditableTableViewCell * cell = (EditableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
			[cell setFirstResponder];
		}
	} else {
		AProposViewController * controller = [[AProposViewController alloc] initWithLicenseType:ApplicationLicenseTypeMIT];
		controller.author = @"Lis@cintosh";
		[controller setURLsStrings:@[ @"lisacintosh.com/iverb-online",
									  @"appstore.com/lisacintosh",
									  @"support.lisacintosh.com/iverb",
									  @"lisacintosh.com" ]];
		controller.repositoryURL = [NSURL URLWithString:@"https://github.com/lisapple/iverb"];
		
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		if (TARGET_IS_IPAD())
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self.navigationController presentViewController:navigationController animated:YES completion:nil];
	}
}

- (void)launchQuizForPlaylist:(Playlist *)playlist
{
    QuizViewController * quizViewController = [[QuizViewController alloc] initWithPlaylist:playlist];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:quizViewController];
	if (TARGET_IS_IPAD()) {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.view.window.rootViewController presentViewController:navigationController animated:YES completion:NULL];
    } else // iPhone
        [self presentViewController:navigationController animated:YES completion:NULL];
}

- (void)renamePlaylist:(Playlist *)playlist
{
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Rename \"%@\"", playlist.name]
																	message:nil preferredStyle:UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
		textField.tag = kRenamingTextFieldTag;
		textField.text = playlist.name;
	}];
	
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	_renameAlertDefaultAction = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		playlist.name = alert.textFields.firstObject.text;
		assert(playlist.name);
		[playlist.managedObjectContext save:NULL];
		
		// Update the TableView
		[self.tableView beginUpdates];
		NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[[Playlist userPlaylists] indexOfObject:playlist]
													 inSection:2];
		[self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
							  withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
	}];
	[alert addAction:_renameAlertDefaultAction];
	
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)deletePlaylist:(Playlist *)playlist
{
	if ([Playlist playlistForAction:PlaylistActionSelect] == playlist)
		[Playlist setPlaylist:nil forAction:PlaylistActionSelect];
	
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[[Playlist userPlaylists] indexOfObject:playlist]
												 inSection:2];
    // Delete the playlist
    NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
    [context deleteObject:playlist];
    [context save:NULL];
    
    // Reload the TableView
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:UITableViewRowAnimationFade];
    userPlaylists = [Playlist userPlaylists].copy;
    [self.tableView endUpdates];
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskPortrait;
}

@end
