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
#import "NSMutableAttributedString+addition.h"
#import "UIFont+addition.h"

@interface ResultTableViewCell : UITableViewCell
@end

@implementation ResultTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) { }
	return self;
}

@end


@implementation UISegmentedControl (Titles)

- (Array(String))titles
{
	NSMutableArray * titles = [[NSMutableArray alloc] initWithCapacity:self.numberOfSegments];
	for (NSInteger i = 0; i < self.numberOfSegments; ++i)
		[titles addObject:[self titleForSegmentAtIndex:i]];
	return titles;
}

@end

@implementation UIControl (Titles)

- (void)setTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
	Array(String) actions = [self actionsForTarget:target forControlEvent:controlEvents];
	for (NSString * action in actions)
		[self removeTarget:target action:NSSelectorFromString(action) forControlEvents:controlEvents];
	[self addTarget:target action:action forControlEvents:controlEvents];
}

@end

@interface SortTableViewCell : UITableViewCell

@property (nonatomic, strong) UISegmentedControl * segmentedControl;
@property (nonatomic, strong, nullable) Array(String) segmentedTitles;

@end

@implementation SortTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.separatorInset = UIEdgeInsetsZero;
		
		_segmentedControl = [[UISegmentedControl alloc] initWithFrame:CGRectZero];
		_segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
		_segmentedControl.tintColor = [UIColor colorWithRed:201./255. green:201./255. blue:206./255. alpha:1];
		[self.contentView addSubview:_segmentedControl];
		[self.contentView addConstraints:
		 @[ [NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
											toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:7],
			[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
											toItem:_segmentedControl attribute:NSLayoutAttributeBottom multiplier:1 constant:7],
			[NSLayoutConstraint constraintWithItem:_segmentedControl attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
											toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:8],
			[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
											toItem:_segmentedControl attribute:NSLayoutAttributeRight multiplier:1 constant:8] ]];
	}
	return self;
}

- (void)setSegmentedTitles:(Array(String) _Nullable)segmentedTitles
{
	_segmentedTitles = segmentedTitles;
	if (![segmentedTitles isEqualToArray:_segmentedControl.titles]) {
		[_segmentedControl removeAllSegments];
		for (NSString * title in segmentedTitles.reverseObjectEnumerator) {
			[_segmentedControl insertSegmentWithTitle:title atIndex:0 animated:false];
		}
		if (segmentedTitles.count > 0)
			_segmentedControl.selectedSegmentIndex = 0;
	}
}

- (UIEdgeInsets)layoutMargins
{
	return UIEdgeInsetsZero;
}

@end


const NSUInteger kToolbarDeleteItemKey = 'tdik';

typedef NS_ENUM(NSUInteger, HistorySorting) {
	HistorySortingRecent,
	HistorySortingViewed
};

@interface SearchViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate>
{
	BOOL showingAddToPopover; // Only on iPad
	HistorySorting historySorting;
}

@property (nonatomic, strong) UISearchController * searchController;
@property (nonatomic, strong) UIPopoverPresentationController * popoverPresentationController;
@property (nonatomic, strong) UIView * statusBarBackgroundView;
@property (nonatomic, strong) AVSpeechSynthesizer * synthesizer;
@property (nonatomic, assign) BOOL isMenuVisible;

@end

@implementation SearchViewController

- (BOOL)canBecomeFirstResponder
{
	return YES; // For cell pop-up menu
}

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
	[searchResultsViewController.tableView registerClass:ResultTableViewCell.class
								  forCellReuseIdentifier:@"cellID"];
	
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsViewController];
	self.searchController.delegate = self;
	self.searchController.searchResultsUpdater = self;
	[self.searchController.searchBar sizeToFit];
	self.tableView.tableHeaderView = self.searchController.searchBar;
	
	if (TARGET_IOS_8()) {
		// Create opaque background view when searching to hide table view result under status bar
		_statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, 20)];
		_statusBarBackgroundView.backgroundColor = [UIColor colorWithRed:201./255. green:201./255. blue:206./255. alpha:1];
		_statusBarBackgroundView.hidden = YES;
		_statusBarBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
		self.searchController.searchBar.subviews.firstObject.clipsToBounds = NO; // Search bar contains a single subview for content
		[self.searchController.searchBar addSubview:_statusBarBackgroundView];
	}
	
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cellID"];
	[self.tableView registerClass:SortTableViewCell.class forCellReuseIdentifier:@"sortCellID"];
	
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
	[[NSNotificationCenter defaultCenter] addObserverForName:PlaylistDidUpdatedNotification object:nil queue:nil
												  usingBlock:^(NSNotification * note) {
													  if (note.object == _playlist) { [self reloadData]; } }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerWillHideMenuNotification object:nil queue:nil
												  usingBlock:^(NSNotification * note) {
													  [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
												  }];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerDidHideMenuNotification object:nil queue:nil
												  usingBlock:^(NSNotification * note) {
													  self.isMenuVisible = NO;
												  }];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateNavBar
{
	self.navigationItem.rightBarButtonItem.enabled = (_playlist.verbs.count > 0);
	
	BOOL allSelected = (_playlist.verbs.count == checkedVerbs.count);
	NSString * title = [NSString stringWithFormat:(allSelected) ? @"Unselect All (%ld)" : @"Select All (%ld)", (unsigned long)_playlist.verbs.count];
	UIBarButtonItem * selectAllItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain
																	  target:self action:@selector(selectAllAction:)];
	[self.navigationItem setLeftBarButtonItem:(editing) ? selectAllItem : nil
									 animated:YES];
}

- (void)updateToolbar
{
	BOOL buttonsEnabled = (checkedVerbs.count > 0);
	for (UIBarButtonItem * buttonItem in self.navigationController.toolbar.items) {
		buttonItem.enabled = buttonsEnabled;
		if (buttonItem.tag == kToolbarDeleteItemKey)
			buttonItem.title = (checkedVerbs.count > 1) ? @"Remove..." : @"Remove"; // No confirmation if only one verb selected
	}
}

- (void)updateData
{
	if (_playlist.isHistoryPlaylist) {
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUse" ascending:NO];
		sortedKeys = [_playlist.verbs sortedArrayUsingDescriptors:@[ sortDescriptor ]];
		if (historySorting == HistorySortingViewed) {
			Dictionary(String, Number) popularities = [[NSUserDefaults standardUserDefaults] dictionaryForKey:UserDefaultsVerbPopularitiesKey];
			sortedKeys = [sortedKeys sortedArrayUsingComparator:^NSComparisonResult(Verb * verb1, Verb * verb2) {
				NSInteger popularity1 = popularities[verb1.infinitif].integerValue;
				NSInteger popularity2 = popularities[verb2.infinitif].integerValue;
				return ComparisonResult(popularity1, popularity2);
			}];
		}
	} else {
		NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"infinitif" ascending:YES];
		sortedKeys = [_playlist.verbs sortedArrayUsingDescriptors:@[ sortDescriptor ]];
	}
	filteredKeys = sortedKeys.copy;
}

- (void)reloadData
{
	self.title = _playlist.localizedName;
	[self updateNavBar];
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
    if ([beginString isEqualToString:UITableViewIndexSearch])
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
							  atScrollPosition:UITableViewScrollPositionBottom
									  animated:NO];
    
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
		
		void (^handler)(UIAlertAction *) = ^(UIAlertAction * action) {
			[[_playlist mutableSetValueForKey:@"verbs"] removeAllObjects];
			[[ManagedObjectContext sharedContext] save:NULL];
			[self reloadData];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:UserDefaultsVerbPopularitiesKey];
		};
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * const key = UserDefaultsClearHistoryAlertCountKey;
		NSInteger confirmationShownCount = [userDefaults integerForKey:key];
		[userDefaults setInteger:++confirmationShownCount forKey:key];
		
		BOOL shouldShowConfirmation = (confirmationShownCount <= 5); // Only show alert 5 times
		if (shouldShowConfirmation) {
			UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Clear history?" message:nil
																			  preferredStyle:UIAlertControllerStyleAlert];
			[alertController addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:handler]];
			[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
			if (TARGET_IS_IPAD()) {
				alertController.modalPresentationStyle = UIModalPresentationPopover;
				UIPopoverPresentationController * popController = alertController.popoverPresentationController;
				popController.barButtonItem = self.navigationItem.rightBarButtonItem;
			}
			[self presentViewController:alertController animated:YES completion:NULL];
		} else {
			handler(nil);
		}
	}
}

- (IBAction)toogleEditingAction:(id)sender
{
	editing = !editing;
	
	const BOOL animated = YES;
	[self.navigationController setToolbarHidden:!editing animated:animated];
	
    UIBarButtonItem * removeItem = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain
																   target:self action:@selector(removeAction:)];
    removeItem.tintColor = [UIColor redColor];
	removeItem.tag = kToolbarDeleteItemKey;
	
	UIBarButtonItem * spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
																				target:nil action:NULL];
	spaceItem.width = 20.;
    
    NSArray * toolbarItems = @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																			  target:self action:@selector(shareAction:)],
								spaceItem,
								[[UIBarButtonItem alloc] initWithTitle:@"Add to..." style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(addToAction:)],
                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL],
                                removeItem ];
    [self.navigationController.toolbar setItems:toolbarItems animated:animated];
	
	[self.navigationItem setHidesBackButton:editing animated:animated];
	
	[checkedVerbs removeAllObjects];
	[self updateNavBar];
	[self updateToolbar];
	
    UIBarButtonSystemItem item = (editing) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
	UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:@selector(toogleEditingAction:)];
	[self.navigationItem setRightBarButtonItem:rightBarItem animated:animated];
	
	[self.tableView reloadData];
}

- (IBAction)selectAllAction:(id)sender
{
	BOOL allSelected = (_playlist.verbs.count == checkedVerbs.count);
	[checkedVerbs removeAllObjects];
	if (!allSelected) {
		[checkedVerbs addObjectsFromArray:_playlist.verbs.allObjects];
	}
	[self updateNavBar];
	[self updateToolbar];
	[self.tableView reloadData];
}

- (IBAction)changeOrderAction:(id)sender
{
	UISegmentedControl * segmentedControl = (UISegmentedControl *)sender;
	historySorting = segmentedControl.selectedSegmentIndex;
	[self reloadData];
}

- (void)copyAction:(id)sender
{
	NSIndexPath * indexPath = self.tableView.indexPathForSelectedRow;
	Verb * verb = filteredKeys[indexPath.row];
	NSString * description = verb.attributedDescription.string;
	[[UIPasteboard generalPasteboard] setValue:description forPasteboardType:@"public.text"]; // @TODO: Set as attrbuted string
}

- (void)listenAction:(id)sender
{
	NSIndexPath * indexPath = self.tableView.indexPathForSelectedRow;
	Verb * verb = filteredKeys[indexPath.row];
	
	NSString * string = [NSString stringWithFormat:@"to %@, %@, %@", verb.infinitif, verb.past, verb.pastParticiple];
	if ([verb.infinitif isEqualToString:verb.past] && [verb.infinitif isEqualToString:verb.pastParticiple])
		string = [NSString stringWithFormat:@"to %@", verb.infinitif];
	
	self.synthesizer = [[AVSpeechSynthesizer alloc] init];
	AVSpeechUtterance * utterance = [AVSpeechUtterance speechUtteranceWithString:string];
	utterance.rate = 0.1;
	[_synthesizer speakUtterance:utterance];
}

- (void)addToFromMenuAction:(id)sender
{
	NSIndexPath * indexPath = self.tableView.indexPathForSelectedRow;
	Verb * verb = filteredKeys[indexPath.row];
	[checkedVerbs removeAllObjects];
	[checkedVerbs addObject:verb];
	[self addToAction:sender];
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
		NSMutableArray <NSAttributedString *> * attrStrings = [[NSMutableArray alloc] initWithCapacity:checkedVerbs.count];
		for (Verb * verb in checkedVerbs) {
			[attrStrings addObject:verb.attributedDescription];
			if (verb != checkedVerbs.lastObject)
				[attrStrings addObject:[[NSAttributedString alloc] initWithString:@"\n\n"]];
		}
		
		NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc] init];
		for (NSAttributedString * string in attrStrings) {
			[attrString appendAttributedString:string];
		}
		
		UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:@[ attrString ]
																						  applicationActivities:nil];
		if (TARGET_IS_IPAD()) {
			activityController.modalPresentationStyle = UIModalPresentationPopover;
			UIPopoverPresentationController * popController = activityController.popoverPresentationController;
			popController.barButtonItem = sender;
		}
		[self presentViewController:activityController animated:YES completion:NULL];
	}
}

- (IBAction)removeFromMenuAction:(id)sender
{
	NSIndexPath * indexPath = self.tableView.indexPathForSelectedRow;
	Verb * verb = filteredKeys[indexPath.row];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	[[_playlist mutableSetValueForKey:@"verbs"] removeObject:verb];
	[self updateData];
	[self.tableView endUpdates];
}

- (IBAction)removeAction:(id)sender
{
	if (checkedVerbs.count > 0) {
		void (^handler)(UIAlertAction * action) = ^(UIAlertAction * action) {
			for (Verb * verb in checkedVerbs)
				[[_playlist mutableSetValueForKey:@"verbs"] removeObject:verb];
			
			[checkedVerbs removeAllObjects];
			[self reloadData];
			[self toogleEditingAction:nil];
		};
		
		if (checkedVerbs.count > 1) {
			NSString * title = [NSString stringWithFormat:@"Remove %ld verbs from \"%@\"?", (long)checkedVerbs.count, _playlist.localizedName];
			UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil
																			  preferredStyle:UIAlertControllerStyleActionSheet];
			[alertController addAction:[UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:handler]];
			[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
			
			if (TARGET_IS_IPAD()) {
				alertController.modalPresentationStyle = UIModalPresentationPopover;
				UIPopoverPresentationController * popController = alertController.popoverPresentationController;
				popController.barButtonItem = sender;
			}
			[self presentViewController:alertController animated:YES completion:NULL];
		} else {
			handler(nil);
		}
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

- (BOOL)shouldShowSortingControlInTableView:(UITableView *)tableView
{
	BOOL searching = (tableView != self.tableView);
	return (_playlist.isHistoryPlaylist && !searching);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self shouldShowSortingControlInTableView:tableView] + filteredKeys.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 0 && [self shouldShowSortingControlInTableView:tableView])
		return 36.;
	
	return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 0 && [self shouldShowSortingControlInTableView:tableView]) {
		static NSString * cellID = @"sortCellID";
		SortTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
		cell.segmentedTitles = @[ @"More recent", @"Most viewed" ];
		[cell.segmentedControl setTarget:self action:@selector(changeOrderAction:) forControlEvents:UIControlEventValueChanged];
		cell.segmentedControl.selectedSegmentIndex = historySorting;
		return cell;
	} else {
		static NSString * cellID = @"cellID";
		UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
		cell.textLabel.textColor = [UIColor darkGrayColor];
		
		NSInteger index = indexPath.row - ([self shouldShowSortingControlInTableView:tableView]);
		if (index >= filteredKeys.count) { // Production debug code to catch a crash
			CLSLog(@"Querying verb at index %ld of %ld from playlist %@ (%ld verbs), searching for: \"%@\"",
				   (long)index, (long)filteredKeys.count, _playlist.name, (long)_playlist.verbs.count, self.searchController.searchBar.text);
		}
		
		Verb * verb = filteredKeys[index];
		NSString * search = self.searchController.searchBar.text;
		if (isSearching && search.length > 0) {
			NSString * title = [NSString stringWithFormat:@"%@, %@, %@", verb.infinitif, verb.past, verb.pastParticiple];
			CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
			cell.textLabel.attributedText = [title highlightOccurrencesOfString:search fontSize: fontSize];
			
			cell.detailTextLabel.text = @""; // This line fix a bug on iOS 8 where the attributed detail text don't shows up on first letter searched
			CGFloat detailFontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote].pointSize;
			cell.detailTextLabel.attributedText = [verb.definition highlightOccurrencesOfString:search fontSize:detailFontSize];
		} else {
			cell.textLabel.text = verb.infinitif;
			cell.detailTextLabel.attributedText = nil;
		}
		cell.accessoryType = ([checkedVerbs containsObject:verb] && editing) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		return cell;
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!editing && !isSearching) {
		dispatch_async(dispatch_get_main_queue(), ^{
			UIMenuController * menu = [UIMenuController sharedMenuController];
			NSMutableArray * menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyAction:)],
											[[UIMenuItem alloc] initWithTitle:@"Add to..." action:@selector(addToFromMenuAction:)],
											[[UIMenuItem alloc] initWithTitle:@"Listen" action:@selector(listenAction:)] ].mutableCopy;
			if (!_playlist.isDefaultPlaylist) {
				[menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeFromMenuAction:)]];
			}
			menu.menuItems = menuItems;
			
			UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
			[menu setTargetRect:CGRectMake(CGRectGetMidX(cell.bounds), CGRectGetMidY(cell.bounds), 1, 1) inView:cell];
			[menu setMenuVisible:YES animated:YES];
			_isMenuVisible = YES;
		});
	}
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { return NO; }
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { }

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

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return !(_isMenuVisible && ![UIMenuController sharedMenuController].isMenuVisible);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (_isMenuVisible && [UIMenuController sharedMenuController].isMenuVisible) {
		return ;
	}
	
	NSInteger index = indexPath.row - [self shouldShowSortingControlInTableView:tableView];
	if (index == -1) return;
	
	Verb * verb = filteredKeys[index];
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
		[self updateNavBar];
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
			
			if (self.navigationController.navigationBarHidden) { // If the navigation bar is hidden, re-show it (with animation) and wait before pushing the result view controller
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
		NSOrderedSet * allVerbs = [NSOrderedSet orderedSetWithArray:sortedKeys];
		
		NSPredicate * predicate = [NSPredicate predicateWithFormat:
								   @"SELF.infinitif CONTAINS[cd] %@ "
								   @"OR SELF.past CONTAINS[cd] %@ "
								   @"OR SELF.pastParticiple CONTAINS[cd] %@",
								   searchText, searchText, searchText];
		NSMutableOrderedSet * verbs = [allVerbs filteredOrderedSetUsingPredicate:predicate].mutableCopy;
		
		NSPredicate * definitionPredicate = [NSPredicate predicateWithFormat:
											 @"SELF.searchableDefinition CONTAINS[cd] %@",
											 searchText];
		NSOrderedSet * definitionVerbs = [allVerbs filteredOrderedSetUsingPredicate:definitionPredicate];
		
		[verbs unionOrderedSet:definitionVerbs];
		filteredKeys = verbs.array;
	} else
		filteredKeys = sortedKeys.copy;
	
	SearchResultsViewController * searchResultsViewController = (SearchResultsViewController *)searchController.searchResultsController;
	[searchResultsViewController.tableView reloadData];
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
	isSearching = NO;
	_statusBarBackgroundView.hidden = YES;
	filteredKeys = sortedKeys.copy;
	[self.tableView reloadSectionIndexTitles];
	[self.tableView reloadData];
	
	[self becomeFirstResponder];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self.searchController.searchBar resignFirstResponder];
	[[UIMenuController sharedMenuController] setMenuVisible:NO]; // Force menu to hide event when scrolling from the cell presenting this menu
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
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
