//
//  SearchViewController.h
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

@import CoreData;
@import MessageUI;
@import Crashlytics;

#import "Playlist.h"

@class Verb;
@interface SearchViewController : UITableViewController <UISearchBarDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate>
{
	NSArray * sortedKeys, * filteredKeys;
	
	UIView * titleView;
	
	BOOL isSearching;// Search Bar is the First Responder, the keyboard is showing
	
	BOOL editing;
	NSMutableArray <Verb *> * checkedVerbs;
}

@property (nonatomic, strong) Playlist * playlist;

- (IBAction)addToAction:(id)sender;
- (IBAction)shareAction:(id)sender;
- (IBAction)removeAction:(id)sender;

- (void)focusSearch;

// Private
- (void)reloadData;

@end
