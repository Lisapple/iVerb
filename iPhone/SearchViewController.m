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

#import "ManagedObjectContext.h"

#import "IndexBarTableView.h"

#define kEmptyActionSheet 1234
#define kShareActionSheet 2345
#define kRemoveActionSheet 3456

@interface SearchViewController ()
{
	id updateObserver;
	
	BOOL showEmpty, showAddTo, showShare, showRemove;
}

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	isSearching = NO;
	editing = NO;
	
    self.clearsSelectionOnViewWillAppear = YES;
	
	self.searchDisplayController.searchBar.delegate = self;
	
	/* Show an "Trash" button to empty */
	if (_playlist.isHistoryPlaylist) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                               target:self
                                                                                               action:@selector(emptyHistoryAction:)];
	} else if (!_playlist.isDefaultPlaylist) { /* Show an "Edit" button */
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
																				  style:UIBarButtonItemStylePlain
																				 target:self
																				 action:@selector(toogleEditingAction:)];
	}
	
	[self reloadData];
}

- (void)setPlaylist:(Playlist *)playlist
{
	_playlist = playlist;
	
	if (self.tableView) {
		[self reloadData];
		[self.tableView scrollRectToVisible:CGRectMake(0., 44., self.view.frame.size.width, self.view.frame.size.height) animated:NO];
	}
	
	if (!_playlist.isDefaultPlaylist) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
																				  style:UIBarButtonItemStylePlain
																				 target:self
																				 action:@selector(toogleEditingAction:)];
	}
}

- (void)reloadData
{
	self.title = NSLocalizedString(_playlist.name, nil); // Convert "_ALL_VERBS_", "_BASICS_VERBS_", "_BOOKMARKS_", "_HISTORY_" to correct title, skip user's playlists title
	
	NSArray * verbs = nil;
	if ([_playlist.name isEqualToString:@"_HISTORY_"] && _playlist.isDefaultPlaylist) {
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUse" ascending:NO];
		verbs = [_playlist.verbs sortedArrayUsingDescriptors:@[sortDescriptor]];
	} else {
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"infinitif" ascending:YES];
		verbs = [_playlist.verbs sortedArrayUsingDescriptors:@[sortDescriptor]];
	}
	
	sortedKeys = [[NSArray alloc] initWithArray:verbs];
	filteredKeys = [[NSArray alloc] initWithArray:verbs];
	
	[self.tableView reloadData];
}

- (NSInteger)indexOfObjectBeginingWith:(NSString *)aChar
{
    if ([aChar isEqualToString:UITableViewIndexSearch]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
							  atScrollPosition:UITableViewScrollPositionBottom
									  animated:NO];
    }
    
	NSInteger index = 0;
	for (Verb * verb in filteredKeys) {
		NSString * stringChar = [verb.infinitif substringWithRange:NSMakeRange(0, 1)];
		if ([aChar compare:stringChar options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			return index;
		}
		index++;
	}
	return -1;
}

#pragma mark - Editing

- (IBAction)emptyHistoryAction:(id)sender
{
	if (!showEmpty) {
		showEmpty = YES;
		
		if (_playlist.verbs.count > 0) {
			if (TARGET_IS_IPAD()) {
				UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"Would you really want to empty the history?"
																		  delegate:self
																 cancelButtonTitle:@"Cancel"
															destructiveButtonTitle:@"Empty"
																 otherButtonTitles:nil];
				actionSheet.tag = kEmptyActionSheet;
				[actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:NO];
			} else {
				ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:@"Would you really want to empty the history?"
																	  delegate:self
															 cancelButtonTitle:@"Cancel"
														destructiveButtonTitle:@"Empty"
															 otherButtonTitles:nil];
				actionSheet.tag = kEmptyActionSheet;
				[actionSheet showInView:self.view];
			}
		}
	}
}

- (IBAction)toogleEditingAction:(id)sender
{
	editing = !editing;
    
    self.navigationController.toolbarHidden = !editing;
    
    UIBarButtonItem * removeItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(removeAction:)];
    removeItem.tintColor = [UIColor redColor];
    
    NSArray * toolbarItems = @[ [[UIBarButtonItem alloc] initWithTitle:@"Add to..."
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(addToAction:)],
                                [[UIBarButtonItem alloc] initWithTitle:@"Share"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(shareAction:)],
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                                removeItem ];
    [self.navigationController.toolbar setItems:toolbarItems animated:YES];
	
	self.navigationItem.hidesBackButton = editing;
    
	if (editing)
		checkedVerbs = [[NSMutableArray alloc] initWithCapacity:10];
    
    enum UIBarButtonSystemItem item = (editing) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item
                                                                                           target:self
                                                                                           action:@selector(toogleEditingAction:)];
	[self.tableView reloadData];
}

- (IBAction)addToAction:(id)sender
{
	if (!showAddTo && !showShare && !showRemove) {
		showAddTo = YES;
		if (checkedVerbs.count > 0) {
			
			if (TARGET_IS_IPAD()) {
				
				VerbOptionsViewController_Pad * verbOptionsViewController = [[VerbOptionsViewController_Pad alloc] init];
				verbOptionsViewController.verbs = checkedVerbs;
				popoverController = [[UIPopoverController alloc] initWithContentViewController:verbOptionsViewController];
				popoverController.delegate = self;
				
				CGSize contentSize = popoverController.popoverContentSize;
				contentSize.height = verbOptionsViewController.tableView.contentSize.height;
				popoverController.popoverContentSize = contentSize;
				
				[popoverController presentPopoverFromBarButtonItem:sender
										  permittedArrowDirections:UIPopoverArrowDirectionUp
														  animated:NO];
				
			} else {
				/* Show an actionSheet to select a playlist (or bookmarks) *OR* show the VerbOptionsViewController_Phone */
				VerbOptionsViewController_Phone * optionsViewController = [[VerbOptionsViewController_Phone alloc] init];
				optionsViewController.verbs = checkedVerbs;
				optionsViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
				[self presentViewController:optionsViewController animated:YES completion:NULL];
			}
		}
	}
}

- (IBAction)shareAction:(id)sender
{
	if (!showAddTo && !showShare && !showRemove) {
		showShare = YES;
		if (checkedVerbs.count > 0) {
			
			BOOL canSendMail = [MFMailComposeViewController canSendMail];
			if (TARGET_IS_IPAD()) {
				UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																		  delegate:self
																 cancelButtonTitle:@"Cancel"
															destructiveButtonTitle:nil
																 otherButtonTitles:@"Copy to Pasteboard", ((canSendMail)? @"Send by Mail" : nil), nil];
				actionSheet.tag = kShareActionSheet;
				[actionSheet showFromBarButtonItem:sender animated:NO];
			} else {
				ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:nil
																	  delegate:self
															 cancelButtonTitle:@"Cancel"
														destructiveButtonTitle:nil
															 otherButtonTitles:@"Copy to Pasteboard", ((canSendMail)? @"Send by Mail" : nil), nil];
				actionSheet.tag = kShareActionSheet;
				[actionSheet showInView:self.view];
			}
		}
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if (error) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error when sending mail"
															 message:error.localizedDescription
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil];
		[alertView show];
	}
	
	[controller dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)removeAction:(id)sender
{
	if (!showAddTo && !showShare && !showRemove) {
		showRemove = YES;
		if (checkedVerbs.count > 0) {
			if (TARGET_IS_IPAD()) {
				UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																		  delegate:self
																 cancelButtonTitle:@"Cancel"
															destructiveButtonTitle:[NSString stringWithFormat:@"Remove from %@", _playlist.name]
																 otherButtonTitles:nil];
				actionSheet.tag = kRemoveActionSheet;
				[actionSheet showFromBarButtonItem:sender animated:NO];
			} else {
				/* Show an actionSheet to confirm removing */
				NSString * removeButtonTitle = (_playlist.name.length > 12) ? @"Remove" : [NSString stringWithFormat:@"Remove from \"%@\"", _playlist.name];
				ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:nil
																	  delegate:self
															 cancelButtonTitle:@"Cancel"
														destructiveButtonTitle:removeButtonTitle
															 otherButtonTitles:nil];
				actionSheet.tag = kRemoveActionSheet;
				[actionSheet showInView:self.view];
			}
		}
	}
}

#pragma mark - UITableViewDataSource

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    /* Don't show the IndexBar: on iPad, if the playlist is not a ordered list or if searching is occuring */
	if (!_playlist.canBeModified && !isSearching) {
		
        if (_playlist.isBasicPlaylist) return @[UITableViewIndexSearch, @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"K", @"L", @"M", @"P", @"Q", @"R", @"S", @"T", @"W"];
        else return @[UITableViewIndexSearch, @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"W"];
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
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		cell.textLabel.textColor = [UIColor darkGrayColor];
	}
	
	Verb * verb = filteredKeys[indexPath.row];
	cell.textLabel.text = [verb valueForKey:@"Infinitif"];
	
	// Clear checkmarks when after editing
	if (!editing)
		cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (_playlist.isUserPlaylist || _playlist.isBookmarksPlaylist);
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Verb * selectedVerb = filteredKeys[indexPath.row];
    [[_playlist mutableSetValueForKey:@"verbs"] removeObject:selectedVerb];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Verb * verb = filteredKeys[indexPath.row];
	if (editing) {
		
		UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
		if ([checkedVerbs containsObject:verb]) { //  Show the checked image
			[checkedVerbs removeObject:verb];
			cell.accessoryType = UITableViewCellAccessoryNone;;
		} else {
			[checkedVerbs addObject:verb];
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	} else {
        
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			
			double delayInSeconds = 0.;
			if (self.navigationController.navigationBarHidden) {// If the navigation bar is hidden, re-show it (with animation) and wait before pushing the result view controller
				delayInSeconds = UINavigationControllerHideShowBarDuration;
				[self.navigationController setNavigationBarHidden:NO
														 animated:YES];
			}
			
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				ResultViewController * resultViewController = [[ResultViewController alloc] init];
				resultViewController.verb = verb;
				[self.navigationController pushViewController:resultViewController animated:YES];
			});
			
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchTableViewDidSelectCellNotification"
																object:verb];
		}
	}
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar
{
	if (!isSearching) {
		[aSearchBar setShowsCancelButton:YES animated:YES];
		isSearching = YES;
		
		[self.tableView reloadSectionIndexTitles];
		[self.tableView reloadData];
	}
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (searchText.length > 0) {
		NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF.infinitif CONTAINS[cd] %@", searchText];
		filteredKeys = [sortedKeys filteredArrayUsingPredicate:predicate];
	} else {
		filteredKeys = sortedKeys.copy;
	}
	
	[self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
	[aSearchBar resignFirstResponder];
    
    filteredKeys = sortedKeys.copy;
    [self.tableView reloadData];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)aSearchBar
{
	isSearching = NO;
	[self.tableView reloadSectionIndexTitles];
	[self.tableView reloadData];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	showAddTo = NO;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kEmptyActionSheet) {
		if (buttonIndex == 0) { // "Empty"
			[[_playlist mutableSetValueForKey:@"verbs"] removeAllObjects];
			[[ManagedObjectContext sharedContext] save:NULL];
			[self reloadData];
		}
		showEmpty = NO;
		
	} else if (actionSheet.tag == kShareActionSheet) {
		
		switch (buttonIndex) {
			case 0: {// "Copy to Pasteboard"
				/* Copy to pasteboard ("Infinitif\nSimple Past\nPP\n\nDefinition\n\n") */
				NSString * body = @"";
				for (Verb * verb in checkedVerbs)
					body = [body stringByAppendingFormat:@"%@, %@, %@\n%@\n\n", verb.infinitif, verb.past, verb.pastParticiple, verb.definition];
				
				UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
				pasteboard.string = body;
			}
				break;
			case 1: {// "Send by Mail"
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
			}
				break;
			default: // "Cancel"
				break;
		}
		showShare = NO;
		
	} else if (actionSheet.tag == kRemoveActionSheet) {
		
		if (buttonIndex == 0) { // "Remove from [name]"
			for (Verb * verb in checkedVerbs) {
				[[_playlist mutableSetValueForKey:@"verbs"] removeObject:verb];
			}
			
			[self reloadData];
		}
		showRemove = NO;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	updateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"PlaylistDidUpdatedNotification"
																	   object:nil
																		queue:[NSOperationQueue currentQueue]
																   usingBlock:^(NSNotification *note) {
																	   if (note.object == _playlist) [self reloadData];
																   }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	NSIndexPath * selectedRows = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:selectedRows animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:updateObserver];
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscape;
}

@end
