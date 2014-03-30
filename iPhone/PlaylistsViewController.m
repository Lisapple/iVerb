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

#import "MyTableViewCell.h"
#import "ConfirmationButton.h"
#import "MoreTableViewCell.h"

#import "UIBarButtonItem+addition.h"

#import "Playlist+additions.h"

#define kConfirmationButtonTag 4567

#define kAlertInfo 1234
#define kAlertMore 2345

@implementation PlaylistsViewController

@synthesize tableView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	self.title = @"Verbs Lists";
	self.navigationController.delegate = self;
	
	CGRect frame = CGRectMake(2., 0., 23. + 2. * 2, 23.);
	UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = frame;
	[button setImage:[UIImage imageNamed:@"info-button"] forState:UIControlStateNormal];
	[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem * infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.leftBarButtonItem = infoButtonItem;
	
	self.navigationController.navigationBar.layer.masksToBounds = YES;// Remove the drop shadow on iOS6
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	UIEdgeInsets insets = UIEdgeInsetsMake(44., 0., 0., 0.);
	tableView.contentInset = insets;
	tableView.scrollIndicatorInsets = insets;
	
	defaultPlaylists = [Playlist defaultPlaylists];
	
	SearchViewController * searchViewController = [[SearchViewController alloc] init];
	searchViewController.playlist = [Playlist allVerbsPlaylist];
	[self.navigationController pushViewController:searchViewController animated:NO];
	
	self.navigationItem.backBarButtonItem = [UIBarButtonItem backBarButtonItemWithTitle:@"Back"
																				  style:UIBarButtonItemStyleDefault];
	
	rowWithDeleteConfirmation = -1;
	[self reloadData];
	
    [super viewDidLoad];
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadData)
												 name:@"PlaylistDidUpdatedNotification"
											   object:nil];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"iVerb %@\nCopyright © 2013, Lis@cintosh\n", nil), [infoDictionary objectForKey:@"CFBundleShortVersionString"]];
	
	if (TARGET_IS_IPAD()) {
		UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
																  delegate:self
														 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
													destructiveButtonTitle:nil
														 otherButtonTitles:
									   NSLocalizedString(@"Feedback & Support", nil),
									   /*NSLocalizedString(@"Send me an e-mail", nil),*/
									   NSLocalizedString(@"Go to my website", nil),
									   NSLocalizedString(@"See all my applications", nil), nil];
		actionSheet.tag = kAlertInfo;
		[actionSheet showInView:self.view];
		
	} else {
		ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:nil
													 otherButtonTitles:
									 NSLocalizedString(@"Feedback & Support", nil),
									 /*NSLocalizedString(@"Send me an e-mail", nil),*/
									 NSLocalizedString(@"Go to my website", nil),
									 NSLocalizedString(@"See all my applications", nil), nil];
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

- (void)removeCell:(id)sender
{
	UITableViewCell * cell = (UITableViewCell *)[sender superview];
	NSIndexPath * indexPath = [tableView indexPathForCell:cell];
	Playlist * playlist = [userPlaylists objectAtIndex:indexPath.row];
	
	/* Delete the playlist from Core Data */
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	[context deleteObject:playlist];
	[context save:NULL];
	
	/* Reload the TableView */
	[tableView beginUpdates];
	
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
					 withRowAnimation:UITableViewRowAnimationFade];
	
	userPlaylists = [[NSArray alloc] initWithArray:[Playlist userPlaylists]];
	
	[tableView endUpdates];
	
	rowWithDeleteConfirmation = -1;
}

- (void)cellsGestureRecognized:(UIGestureRecognizer *)recognizer
{
	[self cellDidSwipe:(UITableViewCell *)recognizer.view];
}

- (void)cellDidSwipe:(UITableViewCell *)cell
{
	if (rowWithDeleteConfirmation > -1) {
		MoreTableViewCell * oldCell = (MoreTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:2]];
		[[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
		
		Playlist * playlist = [userPlaylists objectAtIndex:rowWithDeleteConfirmation];
		oldCell.showsMoreButton = (playlist.verbs.count > 0);
	}
	
	ConfirmationButton * confirmationButton = [[ConfirmationButton alloc] initWithCell:cell];
	confirmationButton.tag = kConfirmationButtonTag;
	confirmationButton.title = @"Delete";
	[confirmationButton addTarget:self
						   action:@selector(removeCell:)
				 forControlEvents:UIControlEventTouchUpInside];
	
	confirmationButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
	confirmationButton.alpha = 0.;
	[cell addSubview:confirmationButton];
	
	[UIView animateWithDuration:0.15
					 animations:^{
						 confirmationButton.transform = CGAffineTransformIdentity;
						 confirmationButton.alpha = 1.;
					 }
					 completion:NULL];
	
	rowWithDeleteConfirmation = [tableView indexPathForCell:cell].row;
	((MoreTableViewCell *)cell).showsMoreButton = NO;
}

- (void)reloadData
{
	userPlaylists = [[NSArray alloc] initWithArray:[Playlist userPlaylists]];
	
	[tableView reloadSections:[NSIndexSet indexSetWithIndex:2]
			 withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	if (userPlaylists.count > 0) {
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:2]
				 withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	[Playlist setCurrentPlaylist:nil];
	
	NSIndexPath * selectedRows = [tableView indexPathForSelectedRow];
	[tableView deselectRowAtIndexPath:selectedRows animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)editableCellDidBeginEditing:(EditableTableViewCell *)cell
{
	NSDebugLog(@"editableCellDidBeginEditing");
	
	UIEdgeInsets insets = UIEdgeInsetsMake(44., 0., 216., 0.);
	tableView.contentInset = insets;
	tableView.scrollIndicatorInsets = insets;
	[tableView scrollToRowAtIndexPath:[tableView indexPathForCell:cell]
					 atScrollPosition:UITableViewScrollPositionTop
							 animated:YES];
}

- (void)editableCellDidEndEditing:(EditableTableViewCell *)cell
{
	NSDebugLog(@"editableCellDidEndEditing: %@", cell.fieldValue);
	
	UIEdgeInsets insets = UIEdgeInsetsMake(44., 0., 0., 0.);
	tableView.contentInset = insets;
	tableView.scrollIndicatorInsets = insets;
	[tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
					 atScrollPosition:UITableViewScrollPositionTop
							 animated:YES];
	
	NSString * name = cell.fieldValue;
	if (name.length > 0) {
		[self createNewListWithName:name];
		[self reloadData];
	}
}

#pragma mark UITableViewDataSource

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
		
		cell = (MyTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell)
			cell = [[MyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		
		Playlist * playlist = [defaultPlaylists objectAtIndex:indexPath.row];
		cell.textLabel.text = NSLocalizedString(playlist.name, nil);
		
	} else if (indexPath.section == 1) {
		
		cell = (MyTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell)
			cell = [[MyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		
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
			cell = (MoreTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:userCellID];
			
			if (!cell) {
				cell = [[MoreTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:userCellID];
				
				UISwipeGestureRecognizer * recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cellsGestureRecognized:)];
				recognizer.direction = (UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight);
				[cell addGestureRecognizer:recognizer];
			}
			
			Playlist * playlist = [userPlaylists objectAtIndex:indexPath.row];
			cell.textLabel.text = NSLocalizedString(playlist.name, nil);
			
			/* If the playlist is not empty, show the number of verbs */
			cell.detailTextLabel.text = (playlist.verbs.count > 0)? [NSString stringWithFormat:@"%ld verbs", (unsigned long)playlist.verbs.count] : @"";
			
			if (indexPath.row == rowWithDeleteConfirmation) {
				ConfirmationButton * confirmationButton = [[ConfirmationButton alloc] initWithCell:cell];
				confirmationButton.tag = kConfirmationButtonTag;
				confirmationButton.title = @"Delete";
				[confirmationButton addTarget:self
									   action:@selector(removeCell:)
							 forControlEvents:UIControlEventTouchUpInside];
				
				/* Offset the button from 4px to the left */
				CGRect frame = confirmationButton.frame;
				frame.origin.x -= 4.;
				confirmationButton.frame = frame;
				
				confirmationButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
				confirmationButton.alpha = 0.;
				[cell addSubview:confirmationButton];
				
				[UIView animateWithDuration:0.15
								 animations:^{
									 confirmationButton.transform = CGAffineTransformIdentity;
									 confirmationButton.alpha = 1.;
								 }
								 completion:^(BOOL finished) {
								 }];
			} else {
				[[cell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
			}
			
			/* Hide the "more" button on empty list */
			((MoreTableViewCell *)cell).showsMoreButton = (playlist.verbs.count > 0);
			((MoreTableViewCell *)cell).moreTarget = self;
			((MoreTableViewCell *)cell).moreAction = @selector(moreCellDidSelectedAction:);
		}
	}
	
	return cell;
}

- (IBAction)moreCellDidSelectedAction:(id)sender
{
	UITableViewCell * cell = (UITableViewCell *)sender;
	NSInteger row = [tableView indexPathForCell:cell].row;
	selectedPlaylist = [userPlaylists objectAtIndex:row];
	
	if (TARGET_IS_IPAD()) {
		UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																  delegate:self
														 cancelButtonTitle:@"Cancel"
													destructiveButtonTitle:@"Delete"
														 otherButtonTitles:@"Launch the Quiz", /*@"Rename",*/ nil];
		actionSheet.tag = kAlertMore;
		
		CGRect newFrame = CGRectOffset(cell.frame, 130., 44. + 20.);
		
		[actionSheet showFromRect:newFrame inView:self.view animated:NO];
	} else {
		ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:nil
															  delegate:self
													 cancelButtonTitle:@"Cancel"
												destructiveButtonTitle:@"Delete"
													 otherButtonTitles:@"Launch the Quiz", /*@"Rename",*/ nil];
		actionSheet.tag = kAlertMore;
		[actionSheet showInView:self.view];
	}
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (rowWithDeleteConfirmation > -1) {
		MoreTableViewCell * oldCell = (MoreTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:2]];
		[[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
		
		Playlist * playlist = [userPlaylists objectAtIndex:rowWithDeleteConfirmation];
		oldCell.showsMoreButton = (playlist.verbs.count > 0);
		
		rowWithDeleteConfirmation = -1;
	}
	
	if (indexPath.section == 0) {
		
		Playlist * playlist = [defaultPlaylists objectAtIndex:indexPath.row];
		[Playlist setCurrentPlaylist:playlist];
		
		SearchViewController * searchViewController = [[SearchViewController alloc] init];
		searchViewController.playlist = playlist;
		[self.navigationController pushViewController:searchViewController animated:YES];
		
	} else if (indexPath.section == 1) {
		
		CloudViewController * cloudViewController = [[CloudViewController alloc] init];
		
		if (TARGET_IS_IPAD()) {
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:cloudViewController];
			
			navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.9 alpha:1.];
			navigationController.navigationBar.translucent = YES;
			
			navigationController.navigationBar.layer.masksToBounds = YES;// Remove the drop shadow on iOS6
			
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			
			[self presentModalViewController:navigationController animated:YES];
			
			/* Deselect the cell */
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
		} else {
			[self.navigationController pushViewController:cloudViewController animated:YES];
		}
		
	} else {
		if (indexPath.row <= (NSInteger)(userPlaylists.count - 1)) {
			
			Playlist * playlist = [userPlaylists objectAtIndex:indexPath.row];
			[Playlist setCurrentPlaylist:playlist];
			
			SearchViewController * searchViewController = [[SearchViewController alloc] init];
			searchViewController.playlist = playlist;
			[self.navigationController pushViewController:searchViewController animated:YES];
		} else {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
	}
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if (rowWithDeleteConfirmation > -1) {
		MoreTableViewCell * oldCell = (MoreTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:2]];
		[[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
		
		Playlist * playlist = [userPlaylists objectAtIndex:rowWithDeleteConfirmation];
		oldCell.showsMoreButton = (playlist.verbs.count > 0);
		
		rowWithDeleteConfirmation = -1;
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
				/*case 1:// Send me an e-mail
				 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://4automator@googlemail.com"]];
				 break;*/
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
			case 0:// "Delete"
				break;
			case 1: {// "Launch the Quiz"
				QuizViewController * quizViewController = [[QuizViewController alloc] init];
				quizViewController.playlist = selectedPlaylist;
				
				UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:quizViewController];
				
				navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.9 alpha:1.];
				navigationController.navigationBar.translucent = YES;
				
				navigationController.navigationBar.layer.masksToBounds = YES;// Remove the drop shadow on iOS6
				
				if (TARGET_IS_IPAD()) {
					navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
				}
				
				[self presentModalViewController:navigationController animated:YES];
			}
				break;
			default:// Cancel
				break;
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (TARGET_IS_IPAD())
		return (UIDeviceOrientationIsLandscape(interfaceOrientation) || UIDeviceOrientationIsPortrait(interfaceOrientation));
	else
		return NO;
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

@end
