//
//  SearchViewController.h
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MessageUI/MessageUI.h>

#import "IVTableViewController.h"

#import "Playlist.h"

#import "ActionSheet.h"

@class Verb;
@interface SearchViewController : IVTableViewController <UISearchBarDelegate, MFMailComposeViewControllerDelegate, ActionSheetDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate>
{
	NSArray * sortedKeys, * filteredKeys;
	
	UIView * titleView;
	
	BOOL isSearching;// Search Bar is the First Responder, the keyboard is showing
	/*
	UITableViewCell * cellWithDeleteConfirmation;
	NSInteger rowWithDeleteConfirmation;
	*/
	BOOL editing;
	NSMutableArray * checkedVerbs;
	
	UIPopoverController * popoverController;
}

@property (nonatomic, strong) IBOutlet UIView * headerView;
//@property (nonatomic, strong) IBOutlet UIToolbar * toolbar;

@property (nonatomic, strong) Playlist * playlist;

- (IBAction)addToAction:(id)sender;
- (IBAction)shareAction:(id)sender;
- (IBAction)removeAction:(id)sender;

// Private
- (void)reloadData;

/*
- (void)removeCell:(id)sender;
- (void)removeVerb:(Verb *)verb;

- (void)cellsGestureRecognized:(UIGestureRecognizer *)recognizer;
- (void)cellDidSwipe:(UITableViewCell *)cell;
*/

@end
