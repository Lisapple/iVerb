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

@class Verb;
@interface SearchViewController : IVTableViewController <UISearchBarDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate>
{
	NSArray * sortedKeys, * filteredKeys;
	
	UIView * titleView;
	
	BOOL isSearching;// Search Bar is the First Responder, the keyboard is showing
	
	BOOL editing;
	NSMutableArray * checkedVerbs;
}

@property (nonatomic, strong) Playlist * playlist;

- (IBAction)addToAction:(id)sender;
- (IBAction)shareAction:(id)sender;
- (IBAction)removeAction:(id)sender;

- (void)focusSearch;

// Private
- (void)reloadData;

@end
