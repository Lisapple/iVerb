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

NS_ASSUME_NONNULL_BEGIN

@class Verb;
@interface SearchViewController : UITableViewController
	<UISearchBarDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) Playlist * playlist;

- (void)focusSearch;

- (nullable Verb *)verbBefore:(Verb *)verb;
- (nullable Verb *)verbAfter:(Verb *)verb;

@end

NS_ASSUME_NONNULL_END
