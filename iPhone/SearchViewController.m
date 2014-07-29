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

#import "MyTableViewCell.h"
#import "ConfirmationButton.h"

#import "IndexBarTableView.h"

#define kAddToActionSheet 1234
#define kShareActionSheet 2345
#define kRemoveActionSheet 3456

@interface SearchViewController ()
{
	id updateObserver;
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
	if (_playlist.verbs.count > 0) {
		if (TARGET_IS_IPAD()) {
			UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:@"Would you really want to empty the history?"
																	  delegate:self
															 cancelButtonTitle:@"Cancel"
														destructiveButtonTitle:@"Empty"
															 otherButtonTitles:nil];
			actionSheet.tag = kAddToActionSheet;
			[actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:NO];
		} else {
			ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:@"Would you really want to empty the history?"
																  delegate:self
														 cancelButtonTitle:@"Cancel"
													destructiveButtonTitle:@"Empty"
														 otherButtonTitles:nil];
			actionSheet.tag = kAddToActionSheet;
			[actionSheet showInView:self.view];
		}
	}
}

- (IBAction)toogleEditingAction:(id)sender
{
	editing = !editing;
	
	//_toolbar.hidden = !editing;
    
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
    
    //[self.navigationController setToolbarItems:toolbarItems animated:YES]; // Doesn't work on iOS 7
    [self.navigationController.toolbar setItems:toolbarItems animated:YES];
	
	self.navigationItem.hidesBackButton = editing;
    
	if (editing)
		checkedVerbs = [[NSMutableArray alloc] initWithCapacity:10];
    
    enum UIBarButtonSystemItem item = (editing) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item
                                                                                           target:self
                                                                                           action:@selector(toogleEditingAction:)];
#if 0
	/* Hide the "Remove" button from cell */
	if (rowWithDeleteConfirmation > -1) {
		UITableViewCell * oldCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:0]];
		[[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
		rowWithDeleteConfirmation = -1;
	}
#endif
	
	[self.tableView reloadData];
}

- (IBAction)addToAction:(id)sender
{
	if (checkedVerbs.count > 0) {
		
		if (TARGET_IS_IPAD()) {
			
			VerbOptionsViewController_Pad * verbOptionsViewController = [[VerbOptionsViewController_Pad alloc] init];
			verbOptionsViewController.verbs = checkedVerbs;
			popoverController = [[UIPopoverController alloc] initWithContentViewController:verbOptionsViewController];
			popoverController.delegate = self;
			
			CGSize contentSize = popoverController.popoverContentSize;
			contentSize.height = verbOptionsViewController.tableView.contentSize.height;
			popoverController.popoverContentSize = contentSize;
			
			UIButton * button = (UIButton *)sender;
			CGRect rect = [button convertRect:button.frame toView:self.view];
			rect.origin.x = 20.;
			
			[popoverController presentPopoverFromRect:rect
											   inView:self.view
							 permittedArrowDirections:UIPopoverArrowDirectionDown
											 animated:NO];
			
		} else {
			/* Show an actionSheet to select a playlist (or bookmarks) *OR* show the VerbOptionsViewController_Phone */
			VerbOptionsViewController_Phone * optionsViewController = [[VerbOptionsViewController_Phone alloc] init];
			optionsViewController.verbs = checkedVerbs;
			optionsViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
			//optionsViewController.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.];
			[self presentViewController:optionsViewController animated:YES completion:NULL];
		}
	}
}

- (IBAction)shareAction:(id)sender
{
	if (checkedVerbs.count > 0) {
		
		BOOL canSendMail = [MFMailComposeViewController canSendMail];
		if (TARGET_IS_IPAD()) {
			UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																	  delegate:self
															 cancelButtonTitle:@"Cancel"
														destructiveButtonTitle:nil
															 otherButtonTitles:@"Copy to Pasteboard", ((canSendMail)? @"Send by Mail" : nil), nil];
			actionSheet.tag = kShareActionSheet;
			
			UIButton * button = (UIButton *)sender;
			CGRect rect = [button convertRect:button.frame toView:self.view];
			rect.origin.x = 105.;
			[actionSheet showFromRect:rect inView:self.view animated:NO];
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
	
	for (UIWindow * window in [UIApplication sharedApplication].windows)
		if ([NSStringFromClass(window.class) isEqualToString:@"BorderMaskWindow"]) window.hidden = NO;
}

- (IBAction)removeAction:(id)sender
{
	if (checkedVerbs.count > 0) {
		if (TARGET_IS_IPAD()) {
			UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																	  delegate:self
															 cancelButtonTitle:@"Cancel"
														destructiveButtonTitle:[NSString stringWithFormat:@"Remove from %@", _playlist.name]
															 otherButtonTitles:nil];
			actionSheet.tag = kRemoveActionSheet;
            
			UIButton * button = (UIButton *)sender;
			CGRect rect = [button convertRect:button.frame toView:self.view];
			rect.origin.x = 225.;
			
			[actionSheet showFromRect:rect inView:self.view animated:NO];
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

#pragma mark - UITableViewDataSource

- (NSArray *)indexTitles
{
    NSArray * allTitles = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"W"];
    NSMutableArray * titles = allTitles.mutableCopy;
    for (NSString * title in allTitles) {
        if ([self indexOfObjectBeginingWith:title] == -1)
            [titles removeObject:titles];
    }
    return titles;
}

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

#if 0
- (NSArray *)sectionIndexTitlesForIndexBarTableView:(IndexBarTableView *)aTableView
{
	/* Don't show the IndexBar: on iPad, if the playlist is not a ordered list or if searching is occuring */
	if (!TARGET_IS_IPAD() && !_playlist.canBeModified && !isSearching) {
		return [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"W", nil];
	}
	
	return nil;
}

- (NSInteger)indexBarTableView:(IndexBarTableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	NSInteger newIndex = [self indexOfObjectBeginingWith:title];
	[aTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]
					  atScrollPosition:UITableViewScrollPositionTop
							  animated:NO];
	
	CGPoint offset = aTableView.contentOffset;
	
	/* Change the offset depending of the iOS version (iOS4 or iOS5+) */
	if ([NSIndexSet instancesRespondToSelector:@selector(enumerateRangesUsingBlock:)]) offset.y -= kHeaderHeight - 44.;
	else offset.y -= 44.;
	
	aTableView.contentOffset = offset;
	
	return newIndex;
}
#endif

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return filteredKeys.count;
}

/*
 - (void)removeCell:(id)sender
 {
 UITableViewCell * cell = (UITableViewCell *)[sender superview];
 NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
 
 [self removeVerb:[filteredKeys objectAtIndex:indexPath.row]];
 
 [self.tableView beginUpdates];
 
 [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
 withRowAnimation:UITableViewRowAnimationFade];
 
 NSArray * verbs = nil;
 if ([_playlist.name isEqualToString:@"_HISTORY_"] && _playlist.isDefaultPlaylist) {
 NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUse" ascending:NO];
 verbs = [_playlist.verbs sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
 } else {
 NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"infinitif" ascending:YES];
 verbs = [_playlist.verbs sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
 }
 
 sortedKeys = [verbs copy];
 filteredKeys = [verbs copy];
 
 [self.tableView endUpdates];
 
 rowWithDeleteConfirmation = -1;
 }
 
 - (void)removeVerb:(Verb *)verb
 {
 [[_playlist mutableSetValueForKey:@"verbs"] removeObject:verb];
 }
 
 - (void)cellsGestureRecognized:(UIGestureRecognizer *)recognizer
 {
 [self cellDidSwipe:(UITableViewCell *)recognizer.view];
 }
 
 - (void)cellDidSwipe:(UITableViewCell *)cell
 {
 if (editing) // Don't show "Remove" button when editing
 return ;
 
 if (rowWithDeleteConfirmation > -1) {
 UITableViewCell * oldCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:0]];
 [[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
 rowWithDeleteConfirmation = -1;
 }
 
 ConfirmationButton * confirmationButton = [[ConfirmationButton alloc] initWithCell:cell];
 confirmationButton.tag = kConfirmationButtonTag;
 confirmationButton.title = @"Remove";
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
 completion:^(BOOL finished) {
 }];
 
 rowWithDeleteConfirmation =  [self.tableView indexPathForCell:cell].row;
 }
 */

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellID = @"cellID";
	MyTableViewCell * cell = (MyTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:cellID];
	
	if (!cell) {
		cell = [[MyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		/*
         if (_playlist.isUserPlaylist) {// Don't add editing on default playlists
         UISwipeGestureRecognizer * recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cellsGestureRecognized:)];
         recognizer.direction = (UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight);
         [cell addGestureRecognizer:recognizer];
         }
         */
	}
	
	Verb * verb = filteredKeys[indexPath.row];
	cell.textLabel.text = [verb valueForKey:@"Infinitif"];
	
	/*
     if (editing) {
     UIView * accessoryView = nil;
     if ([checkedVerbs containsObject:verb]) //  Show the checked image
     accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checked"]];
     else
     accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unchecked"]];
     
     cell.accessoryView = accessoryView;
     
     } else {
     cell.accessoryView = nil;
     }
     */
	/*
     if (indexPath.row == rowWithDeleteConfirmation) {
     ConfirmationButton * confirmationButton = [[ConfirmationButton alloc] initWithCell:cell];
     confirmationButton.tag = kConfirmationButtonTag;
     confirmationButton.title = @"Remove";
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
     completion:^(BOOL finished) {
     }];
     } else {
     [[cell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
     }
     */
	
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
	__block Verb * verb = filteredKeys[indexPath.row];
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
		
        /*
         if (rowWithDeleteConfirmation > -1) {
         UITableViewCell * oldCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:0]];
         [[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
         rowWithDeleteConfirmation = -1;
         }
         */
        
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

#pragma mark - UIScrollView Delegate
#if 0
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if (rowWithDeleteConfirmation > -1) {
		UITableViewCell * oldCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowWithDeleteConfirmation inSection:0]];
		[[oldCell viewWithTag:kConfirmationButtonTag] removeFromSuperview];
		rowWithDeleteConfirmation = -1;
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		CGFloat offsetY = scrollView.contentOffset.y;
		if ((kHeaderHeight - 88.) < offsetY && offsetY < (kHeaderHeight - 44.)) {
			[scrollView setContentOffset:CGPointMake(0, kHeaderHeight - 88.) animated:YES];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	CGFloat offsetY = scrollView.contentOffset.y;
	if ((kHeaderHeight - 88.) < offsetY && offsetY < (kHeaderHeight - 44.)) {
		[scrollView setContentOffset:CGPointMake(0, kHeaderHeight - 88.) animated:YES];
	}
}
#endif
#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)aSearchBar
{
	if (!isSearching) {
		
#if 0
		self.tableView.tableHeaderView = nil;
		CGRect frame = _headerView.frame;
		frame.origin = CGPointMake(0., -(kHeaderHeight - 44.));
		_headerView.frame = frame;
		
		[self.view addSubview:_headerView];
        
		[aSearchBar becomeFirstResponder];
		aSearchBar.delegate = self;
		
		[self.navigationController setNavigationBarHidden:YES
												 animated:YES];
		
		[self.tableView setContentOffset:CGPointMake(0., 0.) animated:NO];
#endif
		[aSearchBar setShowsCancelButton:YES animated:YES];
#if 0
		self.tableView.contentInset = UIEdgeInsetsMake(44., 0., 214. - 44., 0.);
		self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(44., 0., 214. - 44., 0.);
#endif
		isSearching = YES;
		//[self.tableView scrollRectToVisible:CGRectMake(0., 0., 1., 1.) animated:NO];
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
#if 0
	CGRect frame = _headerView.frame;
	frame.origin = CGPointZero;
	_headerView.frame = frame;
	
	self.tableView.tableHeaderView = _headerView;
	
	
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.tableView setContentOffset:CGPointMake(0., -44.) animated:NO];
	
	[aSearchBar setShowsCancelButton:NO animated:YES];
	
	self.tableView.contentInset = UIEdgeInsetsMake(-kHeaderHeight + 88., 0., 0., 0.);
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(44., 0., 0., 0.);
	self.tableView.contentOffset = CGPointMake(0., kHeaderHeight - 44.);
#endif
	isSearching = NO;
	[self.tableView reloadSectionIndexTitles];
	[self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kAddToActionSheet) {
		if (buttonIndex == 0) { // "Empty"
			[[_playlist mutableSetValueForKey:@"verbs"] removeAllObjects];
			[[ManagedObjectContext sharedContext] save:NULL];
			[self reloadData];
		}
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
				
				/* When the mail compose view shows up, the BorderMaskWindow receive all events, hide it to let mail compose receive touch events */
				for (UIWindow * window in [UIApplication sharedApplication].windows)
					if ([NSStringFromClass(window.class) isEqualToString:@"BorderMaskWindow"]) window.hidden = NO;
			}
				break;
                default: // "Cancel"
				break;
		}
		
	} else if (actionSheet.tag == kRemoveActionSheet) {
		
		if (buttonIndex == 0) { // "Remove from [name]"
			for (Verb * verb in checkedVerbs) {
				[[_playlist mutableSetValueForKey:@"verbs"] removeObject:verb];
			}
			
			[self reloadData];
		}
	}
}

/*
 - (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)aViewController animated:(BOOL)animated
 {
 }
 
 - (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
 {
 if (viewController == self) {
 }
 }
 */

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

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (TARGET_IS_IPAD())
		return (UIDeviceOrientationIsLandscape(interfaceOrientation) || UIDeviceOrientationIsPortrait(interfaceOrientation));
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscape;
	//return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

- (void)dealloc
{
	self.navigationController.delegate = nil;
	self.playlist = nil;
	
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
}


@end
