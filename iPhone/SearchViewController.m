//
//  SearchViewController.m
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import "SearchViewController.h"
#import "ResultViewController.h"
#import "VerbOptionsViewController_Phone.h"
#import "VerbOptionsViewController_Pad.h"
#import "SearchResultsViewController.h"

#import "ManagedObjectContext.h"
#import "Playlist+additions.h"

#import "NSString+addition.h"
#import <Crashlytics/Crashlytics.h>

@interface SearchViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate>
{
	BOOL showingAddToPopover; // Only on iPad
}

@property (nonatomic, strong) UISearchController * searchController;
@property (nonatomic, strong) UIPopoverPresentationController * popoverPresentationController;
@property (nonatomic, strong) UIView * statusBarBackgroundView;

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	isSearching = NO;
	editing = NO;
	checkedVerbs = [[NSMutableArray alloc] initWithCapacity:10];
	
    self.clearsSelectionOnViewWillAppear = YES;
	
	SearchResultsViewController * searchResultsViewController = [[SearchResultsViewController alloc] init];
	searchResultsViewController.tableView.delegate = self;
	searchResultsViewController.tableView.dataSource = self;
	
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsViewController];
	self.searchController.delegate = self;
	self.searchController.searchResultsUpdater = self;
	[self.searchController.searchBar sizeToFit];
	self.tableView.tableHeaderView = self.searchController.searchBar;
	
	if (IOS_8_OR_EARLIER()) {
		// Create opaque background view when searching to hide table view result under status bar
		_statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, 20)];
		_statusBarBackgroundView.backgroundColor = [UIColor colorWithRed:201./255. green:201./255. blue:206./255. alpha:1];
		_statusBarBackgroundView.hidden = YES;
		_statusBarBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
		self.searchController.searchBar.subviews.firstObject.clipsToBounds = NO; // Search bar contains a single subview for content
		[self.searchController.searchBar addSubview:_statusBarBackgroundView];
	}
	
	if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
		[self registerForPreviewingWithDelegate:self sourceView:self.tableView];
	}
	
	if /**/ (_playlist.isHistoryPlaylist) { // Show an "Trash" button to empty
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                               target:self action:@selector(emptyHistoryAction:)];
	}
	else if (_playlist.isUserPlaylist) { // Show an "Edit" button
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain
																				 target:self action:@selector(toogleEditingAction:)];
	}
}

- (void)setPlaylist:(Playlist *)playlist
{
	_playlist = playlist;
	
	if (self.tableView) {
		[self reloadData];
		[self.tableView scrollRectToVisible:CGRectMake(0., 44., self.view.frame.size.width, self.view.frame.size.height) animated:NO];
	}
	
	if (!_playlist.isDefaultPlaylist) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain
																				 target:self action:@selector(toogleEditingAction:)];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self reloadData];
	[[NSNotificationCenter defaultCenter] addObserverForName:PlaylistDidUpdatedNotification object:nil
													   queue:nil usingBlock:^(NSNotification *note) { if (note.object == _playlist) { [self reloadData]; } }];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateToolbar
{
	BOOL buttonsEnabled = (checkedVerbs.count > 0);
	for (UIBarButtonItem * buttonItem in self.navigationController.toolbar.items)
		buttonItem.enabled = buttonsEnabled;
}

- (void)updateData
{
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"infinitif" ascending:YES];
	if (_playlist.isHistoryPlaylist)
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUse" ascending:NO];
	
	sortedKeys = [_playlist.verbs sortedArrayUsingDescriptors:@[ sortDescriptor ]];
	filteredKeys = sortedKeys.copy;
}

- (void)reloadData
{
	self.title = _playlist.localizedName;
	[self updateToolbar];
	[self updateData];
	[self.tableView reloadData];
}

- (void)focusSearch
{
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						  atScrollPosition:UITableViewScrollPositionBottom animated:NO];
	[self.searchController.searchBar becomeFirstResponder];
}

- (NSInteger)indexOfObjectBeginingWith:(NSString *)beginString
{
    if ([beginString isEqualToString:UITableViewIndexSearch]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
							  atScrollPosition:UITableViewScrollPositionBottom
									  animated:NO];
    }
    
	NSInteger index = 0;
	for (Verb * verb in filteredKeys) {
		NSString * stringChar = [verb.infinitif substringWithRange:NSMakeRange(0, 1)];
		if ([beginString compare:stringChar options:NSCaseInsensitiveSearch] == NSOrderedSame)
			return index;
		++index;
	}
	return -1;
}

#pragma mark - Editing

- (IBAction)emptyHistoryAction:(id)sender
{
	if (_playlist.verbs.count > 0) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Would you really want to empty the history?" message:nil
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Empty" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * __nonnull action) {
			[[_playlist mutableSetValueForKey:@"verbs"] removeAllObjects];
			[[ManagedObjectContext sharedContext] save:NULL];
			[self reloadData];
		}]];
		
		[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
		
		if (TARGET_IS_IPAD()) {
			alertController.modalPresentationStyle = UIModalPresentationPopover;
			UIPopoverPresentationController * popController = alertController.popoverPresentationController;
			popController.barButtonItem = self.navigationItem.rightBarButtonItem;
		}
		[self presentViewController:alertController animated:YES completion:NULL];
	}
}

- (IBAction)toogleEditingAction:(id)sender
{
	editing = !editing;
    
    self.navigationController.toolbarHidden = !editing;
    
    UIBarButtonItem * removeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
																				 target:self
																				 action:@selector(removeAction:)];
    removeItem.tintColor = [UIColor redColor];
	
	UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
																				target:nil action:NULL];
	spaceItem.width = 20.;
    
    NSArray * toolbarItems = @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																			  target:self
																			  action:@selector(shareAction:)],
								spaceItem,
								[[UIBarButtonItem alloc] initWithTitle:@"Add to..."
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(addToAction:)],
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                                removeItem ];
    [self.navigationController.toolbar setItems:toolbarItems animated:YES];
	
	self.navigationItem.hidesBackButton = editing;
	
	[checkedVerbs removeAllObjects];
	[self updateToolbar];
	
    UIBarButtonSystemItem item = (editing) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item
                                                                                           target:self action:@selector(toogleEditingAction:)];
	[self.tableView reloadData];
}

- (IBAction)addToAction:(id)sender
{
	if (!showingAddToPopover && checkedVerbs.count > 0) {
		if (TARGET_IS_IPAD()) {
			VerbOptionsViewController_Pad * verbOptionsViewController = [[VerbOptionsViewController_Pad alloc] init];
			verbOptionsViewController.verbs = checkedVerbs;
			verbOptionsViewController.modalPresentationStyle = UIModalPresentationPopover;
			
			_popoverPresentationController = verbOptionsViewController.popoverPresentationController;
			_popoverPresentationController.delegate = self;
			[_popoverPresentationController.containerView sizeToFit];
			_popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
			
			[self presentViewController:verbOptionsViewController animated:NO completion:NULL];
			showingAddToPopover = YES;
		
		} else {
			/* Show an actionSheet to select a playlist (or bookmarks) *OR* show the VerbOptionsViewController_Phone */
			VerbOptionsViewController_Phone * optionsViewController = [[VerbOptionsViewController_Phone alloc] init];
			optionsViewController.verbs = checkedVerbs;
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:optionsViewController];
			[self presentViewController:navigationController animated:YES completion:NULL];
		}
	}
}

- (IBAction)shareAction:(id)sender
{
	if (checkedVerbs.count > 0) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Copy to Pasteboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			/* Copy to pasteboard ("Infinitif\nSimple Past\nPP\n\nDefinition\n\n") */
			NSString * body = @"";
			for (Verb * verb in checkedVerbs)
				body = [body stringByAppendingFormat:@"%@, %@, %@\n%@\n\n", verb.infinitif, verb.past, verb.pastParticiple, verb.definition];
			
			UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = body;
		}]];
		
		if ([MFMailComposeViewController canSendMail]) {
			[alertController addAction:[UIAlertAction actionWithTitle:@"Send with Mail" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
				NSString * body = @"<table border=\"0\" style=\"border:1px solid #ccc;width:100%;text-align:center;border-collapse:collapse;\">";
				int index = 0;
				for (Verb * verb in checkedVerbs) {
					body = [body stringByAppendingFormat:@"<tr%@><td>%@</td><td>%@</td><td>%@</td></tr>",
							(index++ % 2 == 0)? @" style=\"background-color:#ddd\"" : @"",
							verb.infinitif, verb.past, verb.pastParticiple];
				}
				body = [body stringByAppendingString:@"</table>"];
				
				MFMailComposeViewController * mailCompose = [[MFMailComposeViewController alloc] init];
				mailCompose.mailComposeDelegate = self;
				[mailCompose setSubject:@"Some irregular verbs from iVerb"];
				[mailCompose setMessageBody:body isHTML:YES];
				[self presentViewController:mailCompose
								   animated:YES
								 completion:NULL];
			}]];
		}
		
		[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
		
		if (TARGET_IS_IPAD()) {
			alertController.modalPresentationStyle = UIModalPresentationPopover;
			UIPopoverPresentationController * popController = alertController.popoverPresentationController;
			popController.barButtonItem = sender;
		}
		[self presentViewController:alertController animated:YES completion:NULL];
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if (error) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error when sending mail"
																				 message:error.localizedDescription
																		  preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
		[self presentViewController:alertController animated:YES completion:NULL];
	}
	
	[controller dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)removeAction:(id)sender
{
	if (checkedVerbs.count > 0) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Remove from \"%@\"", _playlist.localizedName]
															style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
																for (Verb * verb in checkedVerbs)
																	[[_playlist mutableSetValueForKey:@"verbs"] removeObject:verb];
																
																[checkedVerbs removeAllObjects];
																[self reloadData];
															}]];
		
		[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
		
		if (TARGET_IS_IPAD()) {
			alertController.modalPresentationStyle = UIModalPresentationPopover;
			UIPopoverPresentationController * popController = alertController.popoverPresentationController;
			popController.barButtonItem = sender;
		}
		[self presentViewController:alertController animated:YES completion:NULL];
	}
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // Don't show the IndexBar: on iPad, if the playlist is not a ordered list or if searching is occuring
	if (!_playlist.canBeModified && !isSearching) {
		NSString * letters = @"A.B.C.D.E.F.G.H.K.L.M.P.Q.R.S.T.W";
		if (_playlist.isCommonsPlaylist)
			letters = @"B.C.D.E.F.G.H.K.L.M.P.R.S.T.U.W";
		return [@[ UITableViewIndexSearch ] arrayByAddingObjectsFromArray:[letters componentsSeparatedByString:@"."]];
	}
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSInteger newIndex = [self indexOfObjectBeginingWith:title];
    if (newIndex != -1) {
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]
                         atScrollPosition:UITableViewScrollPositionTop
                                 animated:NO];
    }
	return newIndex;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return filteredKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellID = @"cellID";
	UITableViewCell * cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
		cell.textLabel.textColor = [UIColor darkGrayColor];
	}
	
	if (indexPath.row >= filteredKeys.count) { // Production debug code to catch a crash
		CLSLog(@"Querying verb at index %ld of %ld from playlist %@ (%ld verbs), searching for: \"%@\"",
			   (long)indexPath.row, (long)filteredKeys.count, _playlist.name, (long)_playlist.verbs.count, self.searchController.searchBar.text);
	}
	
	Verb * verb = filteredKeys[indexPath.row];
	NSString * search = self.searchController.searchBar.text;
	if (isSearching && search.length > 0) {
		NSString * title = [NSString stringWithFormat:@"%@, %@, %@", verb.infinitif, verb.past, verb.pastParticiple];
		cell.textLabel.attributedText = [title highlightOccurrencesOfString:search fontSize:17.];
		cell.detailTextLabel.text = @""; // This line fix a bug on iOS 8 where the attributed detail text don't shows up on first letter searched
		cell.detailTextLabel.attributedText = [verb.definition highlightOccurrencesOfString:search fontSize:12.];
	} else {
		cell.textLabel.text = verb.infinitif;
		cell.detailTextLabel.attributedText = nil;
	}
	cell.accessoryType = ([checkedVerbs containsObject:verb] && editing) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((_playlist.isUserPlaylist || _playlist.isBookmarksPlaylist) && !isSearching);
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Verb * selectedVerb = filteredKeys[indexPath.row];
    [[_playlist mutableSetValueForKey:@"verbs"] removeObject:selectedVerb];
	
	[tableView beginUpdates];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self updateData];
	[tableView endUpdates];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Verb * verb = filteredKeys[indexPath.row];
	if (editing) {
		
		UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
		if ([checkedVerbs containsObject:verb]) { // Show the checked image
			[checkedVerbs removeObject:verb];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else {
			[checkedVerbs addObject:verb];
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self updateToolbar];
		
	} else {
		if (TARGET_IS_IPAD()) {
			[[NSNotificationCenter defaultCenter] postNotificationName:SearchTableViewDidSelectCellNotification object:verb];
		} else {
			double delayInSeconds = 0.;
			if (_searchController.isActive) {
				_searchController.active = NO;
				delayInSeconds += 0.15;
			}
			
			if (self.navigationController.navigationBarHidden) {// If the navigation bar is hidden, re-show it (with animation) and wait before pushing the result view controller
				delayInSeconds += UINavigationControllerHideShowBarDuration;
				[self.navigationController setNavigationBarHidden:NO
														 animated:YES];
			}
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)),
						   dispatch_get_main_queue(), ^{
							   ResultViewController * resultViewController = [[ResultViewController alloc] init];
							   resultViewController.verb = verb;
							   [self.navigationController pushViewController:resultViewController animated:YES];
						   });
		}
	}
}

#pragma mark - Previewing with 3D Touch

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
	NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
	if (indexPath) {
		Verb * verb = filteredKeys[indexPath.row];
		ResultViewController * resultViewController = [[ResultViewController alloc] init];
		resultViewController.verb = verb;
		return resultViewController;
	}
	
	return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
	[self.navigationController pushViewController:viewControllerToCommit animated:NO];
}

#pragma mark - Search results updating

- (void)didPresentSearchController:(UISearchController *)searchController
{
	isSearching = YES;
	_statusBarBackgroundView.hidden = NO;
	
	if (editing)
		[self toogleEditingAction:nil];
	
	SearchResultsViewController * searchResultsViewController = (SearchResultsViewController *)searchController.searchResultsController;
	const CGFloat topMargin = self.topLayoutGuide.length + self.navigationController.navigationBar.frame.size.height;
	UIEdgeInsets insets = UIEdgeInsetsMake(topMargin, 0., 0., 0.);
	searchResultsViewController.tableView.contentInset = insets;
	searchResultsViewController.tableView.scrollIndicatorInsets = insets;
	
	[self.tableView reloadSectionIndexTitles];
	[self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchText = searchController.searchBar.text;
	if (searchText.length > 0) {
		NSPredicate * predicate = [NSPredicate predicateWithFormat:
								   @"SELF.infinitif CONTAINS[cd] %@ "
								   @"OR SELF.past CONTAINS[cd] %@ "
								   @"OR SELF.pastParticiple CONTAINS[cd] %@ "
								   @"OR SELF.searchableDefinition CONTAINS[cd] %@",
								   searchText, searchText, searchText, searchText];
		filteredKeys = [sortedKeys filteredArrayUsingPredicate:predicate];
	} else
		filteredKeys = sortedKeys.copy;
	
	SearchResultsViewController * searchResultsViewController = (SearchResultsViewController *)searchController.searchResultsController;
	[searchResultsViewController.tableView reloadData];
}

- (void)willDismissSearchController:(nonnull UISearchController *)searchController
{
	isSearching = NO;
	_statusBarBackgroundView.hidden = YES;
	filteredKeys = sortedKeys.copy;
	[self.tableView reloadSectionIndexTitles];
	[self.tableView reloadData];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self.searchController.searchBar resignFirstResponder];
}

- (void)popoverPresentationControllerDidDismissPopover:(nonnull UIPopoverPresentationController *)popoverPresentationController
{
	showingAddToPopover = NO;
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscape;
}

@end
