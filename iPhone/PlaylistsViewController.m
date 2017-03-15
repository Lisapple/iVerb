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
#import "AboutViewController.h"

#import "ManagedObjectContext.h"

#import "Playlist+additions.h"
#import "NSDate+addition.h"
#import "UIApplication+addition.h"

@interface PlaylistsViewController ()

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
	
	if (TARGET_IS_IPAD()) {
		UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoDark];
		[button sizeToFit];
		[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
		button.tintColor = self.view.window.tintColor;
		
		UIBarButtonItem * infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
		self.navigationItem.leftBarButtonItem = infoButtonItem;
	}
	
	defaultPlaylists = [Playlist defaultPlaylists];
	
	[self.tableView registerClass:TableViewCell.class forCellReuseIdentifier:TableViewCell.identifier];
	
	[self reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData)
												 name:PlaylistDidUpdatedNotification object:nil];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [NSBundle mainBundle].infoDictionary;
	NSString * title = [NSString stringWithFormat:@"iVerb %@\nCopyright © %lu, Lis@cintosh", infoDictionary[@"CFBundleShortVersionString"], (long)[NSDate date].year];
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Feedback & Support" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[[UIApplication sharedApplication] openExternalURL:[NSURL URLWithString:@"http://support.lisacintosh.com/iVerb/"]]; }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Go to my website" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[[UIApplication sharedApplication] openExternalURL:[NSURL URLWithString:@"http://lisacintosh.com/"]]; }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"See all my application" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[[UIApplication sharedApplication] openExternalURL:[NSURL URLWithString:@"http://applestore.com/lisacintosh"]]; }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
	
	alertController.modalPresentationStyle = UIModalPresentationPopover;
	UIPopoverPresentationController * popController = alertController.popoverPresentationController;
	popController.permittedArrowDirections = UIPopoverArrowDirectionUp;
	popController.sourceRect = CGRectMake(30., 0., 0., 0.);
	popController.sourceView = self.view;
	[self.view.window.rootViewController presentViewController:alertController animated:YES completion:NULL];
}

- (void)createNewListWithName:(NSString *)name
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:context];
	NSManagedObject * playlist = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
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
	
	[Playlist setPlaylist:nil forAction:PlaylistActionSelect];
}

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
	
	static NSString * cellID = @"CellID";
	if (indexPath.section == 0) { // Default lists
		
		cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
		
		Playlist * playlist = defaultPlaylists[indexPath.row];
		cell.textLabel.text = playlist.localizedName;
        
        cell.detailTextLabel.text = (playlist.isBookmarksPlaylist && playlist.verbs.count > 0) ? [NSString stringWithFormat:@"%lu", (unsigned long)playlist.verbs.count] : @"";
		
	} else if (indexPath.section == 1) { // Cloud
		
		cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
		cell.textLabel.text = @"Cloud";
		
	} else { // User list
		
		if (indexPath.row > (NSInteger)(userPlaylists.count - 1)) { // Cell to create a new playlist
			static NSString * newCellID = @"NewCellID";
			cell = (EditableTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:newCellID];
			if (!cell) {
				cell = [[EditableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newCellID];
				((EditableTableViewCell *)cell).delegate = self;
			}
			((EditableTableViewCell *)cell).fieldValue = nil;
			
		} else { // Existing user lists
			static NSString * userCellID = @"UserCellID";
			cell = [aTableView dequeueReusableCellWithIdentifier:userCellID];
			if (!cell)
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:userCellID];
			
			Playlist * playlist = userPlaylists[indexPath.row];
			cell.textLabel.text = playlist.localizedName;
			
			/* If the playlist is not empty, show the number of verbs */
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
			rowAction.backgroundColor = [UIColor purpleColor];
			[actions addObject:rowAction];
		}
        return actions;
    }
    return nil;
}

- (void)tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	_selectedPlaylist = userPlaylists[indexPath.row];
	
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil
																	  preferredStyle:UIAlertControllerStyleActionSheet];
	if (_selectedPlaylist.verbs.count > 0) {
		[alertController addAction:[UIAlertAction actionWithTitle:@"Launch the Quiz" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			[self launchQuizForPlaylist:_selectedPlaylist]; }]];
	}
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
		[controller setURLsStrings:@[ @"http://lisacintosh.com/iverb-online",
									  @"appstore.com/lisacintosh",
									  @"http://support.lisacintosh.com/iverb",
									  @"http://lisacintosh.com" ]];
		controller.repositoryURL = [NSURL URLWithString:@"https://github.com/lisapple/iverb"];
		
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
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

- (void)deletePlaylist:(Playlist *)playlist
{
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:[[Playlist userPlaylists] indexOfObject:playlist]
												 inSection:2];
	
    /* Delete the playlist from Core Data */
    NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
    [context deleteObject:playlist];
    [context save:NULL];
    
    /* Reload the TableView */
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
