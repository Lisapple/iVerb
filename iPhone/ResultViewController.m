//
//  ResultViewController.m
//  iVerb
//
//  Created by Max on 9/12/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import "ResultViewController.h"

#import "ManagedObjectContext.h"
#import "Playlist+additions.h"

#import "VerbOptionsViewController_Phone.h"
#import "HelpViewController.h"
#import "EditNoteViewController.h"

#import "IVWebView.h"

#import "NSMutableAttributedString+addition.h"
#import "UIFont+addition.h"

@interface ResultViewController ()

@property (nonatomic, strong) IVWebView * webView;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicatorView;
@property (nonatomic, strong) AVSpeechSynthesizer * synthesizer;

@end

@implementation ResultViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSString * infinitif = _verb.infinitif;
	self.title = [@"To " stringByAppendingString:infinitif];
	
	self.navigationItem.rightBarButtonItems = @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																							   target:self action:@selector(showOptionAction:)],
												 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"favorite"]
																				  style:UIBarButtonItemStylePlain
																				 target:self action:@selector(tooggleFavoriteAction:)] ];
	
	WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc] init];
	_webView = [[IVWebView alloc] initWithFrame:CGRectZero configuration:configuration];
	_webView.translatesAutoresizingMaskIntoConstraints = NO;
	_webView.navigationDelegate = self;
	_webView.scrollView.delegate = self;
	[self.view addSubview:_webView];
	[self.view addConstraints:
  @[ [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeRight multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeBottom multiplier:1 constant:0] ]];
	
	
	_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
	_activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
	_activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
	[self.view addSubview:_activityIndicatorView];
	[self.view addConstraints:
	 @[ [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
										toItem:_activityIndicatorView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
										toItem:_activityIndicatorView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0] ]];
	
	[_activityIndicatorView startAnimating];
	
	[self loadResults];
    
	[[NSNotificationCenter defaultCenter] addObserverForName:ResultDidReloadNotification
													  object:nil queue:nil
												  usingBlock:^(NSNotification * notification) {
													  [self loadResults];
												  }];
	[[NSNotificationCenter defaultCenter] addObserverForName:PlaylistDidUpdatedNotification
													  object:nil queue:nil
												  usingBlock:^(NSNotification * notification) {
													  [Playlist setPlaylist:notification.object forAction:PlaylistActionAddTo]; }];
	if (TARGET_IS_IPAD()) {
		[[NSNotificationCenter defaultCenter] addObserverForName:SearchTableViewDidSelectCellNotification
														  object:nil queue:nil
													  usingBlock:^(NSNotification *note) {
														  self.verb = (Verb *)note.object;
														  [self loadResults];
													  }];
	}
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	MDictionary(String, Number) popularities = ([userDefaults dictionaryForKey:UserDefaultsVerbPopularitiesKey] ?: @{}).mutableCopy;
	popularities[_verb.infinitif] = @(popularities[_verb.infinitif].integerValue + 1);
	[userDefaults setObject:popularities forKey:UserDefaultsVerbPopularitiesKey];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self updateUI];
}

- (void)loadResults
{
	NSMutableString * content = _verb.HTMLFormat.mutableCopy;
	CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
	[content replaceOccurrencesOfString:@"{{font-size}}" withString:[NSString stringWithFormat:@"%ldpx", (long)fontSize]
								options:0 range: NSMakeRange(0, content.length)];
	
	NSString * basePath = [NSBundle mainBundle].bundlePath;
	[_webView loadHTMLString:content baseURL:[NSURL fileURLWithPath:basePath]];
	
	_webView.scrollView.showsVerticalScrollIndicator = YES;
	_webView.scrollView.scrollEnabled = YES;
}

- (void)setVerb:(Verb *)verb
{
	_verb = verb;
	
	/* Update the verb from the history */
	_verb.lastUse = [NSDate date];
	[_verb addToPlaylist:[Playlist historyPlaylist]];
	[self updateUI];
}

- (void)tooggleFavoriteAction:(id)sender
{
	if (_verb.isBookmarked) {
		[[Playlist bookmarksPlaylist] removeVerb:_verb];
	} else {
		[[Playlist bookmarksPlaylist] addVerb:_verb];
	}
	[self updateUI];
}

- (void)updateUI
{
	UIBarButtonItem * favoriteItem = self.navigationItem.rightBarButtonItems.lastObject;
	NSString * name = (_verb.isBookmarked) ? @"favorite-highlighted" : @"favorite";
	favoriteItem.image = [UIImage imageNamed:name];
}

- (void)listenAction:(id)sender
{
	NSString * string = [NSString stringWithFormat:@"to %@, %@, %@", _verb.infinitif, _verb.past, _verb.pastParticiple];
	if ([_verb.infinitif isEqualToString:_verb.past] && [_verb.infinitif isEqualToString:_verb.pastParticiple])
		string = [NSString stringWithFormat:@"to %@", _verb.infinitif];
	
	self.synthesizer = [[AVSpeechSynthesizer alloc] init];
	AVSpeechUtterance * utterance = [AVSpeechUtterance speechUtteranceWithString:string];
	utterance.rate = 0.1;
	[_synthesizer speakUtterance:utterance];
}

- (void)shareAction:(id)sender
{
	UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:@[ _verb.attributedDescription ]
																					  applicationActivities:nil];
	if (TARGET_IS_IPAD()) {
		activityController.modalPresentationStyle = UIModalPresentationPopover;
		UIPopoverPresentationController * popController = activityController.popoverPresentationController;
		popController.barButtonItem = sender;
	}
	[self presentViewController:activityController animated:YES completion:NULL];
}

- (NSArray <id <UIPreviewActionItem>> *)previewActionItems
{
	// Return "Add to list..." (group), "Listen" and "Copy"
	NSArray <Playlist *> * playlists = [@[ [Playlist bookmarksPlaylist] ] arrayByAddingObjectsFromArray:[Playlist userPlaylists]];
	NSMutableArray <UIPreviewAction *> * addActions = [[NSMutableArray alloc] initWithCapacity:playlists.count];
	for (Playlist * playlist in playlists) {
		if (![playlist.verbs containsObject:_verb]) {
			[addActions addObject:[UIPreviewAction actionWithTitle:playlist.localizedName
														  style:UIPreviewActionStyleDefault
														   handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
															   [playlist addVerb:_verb];
														   }]];
		}
	}
	
	UIPreviewAction * listenAction = [UIPreviewAction actionWithTitle:@"Listen" style:UIPreviewActionStyleDefault
															  handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
																  [self listenAction:nil]; }];
	
	UIPreviewAction * shareAction = [UIPreviewAction actionWithTitle:@"Share..." style:UIPreviewActionStyleDefault
															 handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
																 [self shareAction:nil]; }];
	
	NSMutableArray <id <UIPreviewActionItem>> * actions = @[ listenAction, shareAction ].mutableCopy;
	if (addActions.count) { // Show the "Add to list..." if the verb is not in all list (the action will not remove any verb, only add to list)
		UIPreviewActionGroup * addToAction = [UIPreviewActionGroup actionGroupWithTitle:@"Add to list..."
																				  style:UIPreviewActionStyleDefault
																				actions:addActions];
		[actions insertObject:addToAction atIndex:0];
	}
	
	Playlist * lastPlaylist = [Playlist playlistForAction:PlaylistActionAddTo];
	if (lastPlaylist && ![lastPlaylist.verbs containsObject:_verb]) {
		UIPreviewAction * addToListAction = [UIPreviewAction actionWithTitle:[NSString stringWithFormat:@"Add to \"%@\"", lastPlaylist.localizedName]
																	   style:UIPreviewActionStyleDefault
																	 handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
																		 [lastPlaylist addVerb:_verb]; }];
		[actions insertObject:addToListAction atIndex:0];
	}
	
	return actions;
}

- (IBAction)showOptionAction:(id)sender
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	
	Playlist * lastPlaylist = [Playlist playlistForAction:PlaylistActionAddTo];
	if (lastPlaylist) {
		NSString * actionString = ([lastPlaylist.verbs containsObject:_verb]) ? @"Remove from" : @"Add to";
		NSString * title = [NSString stringWithFormat:@"%@ \"%@\"", actionString, lastPlaylist.localizedName];
		[alertController addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * _Nonnull action) {
															  if ([lastPlaylist.verbs containsObject:_verb])
																  [lastPlaylist removeVerb:_verb];
															  else
																  [lastPlaylist addVerb:_verb];
															  }]];
	}
	
	[alertController addAction:[UIAlertAction actionWithTitle:@"Add to list..." style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) {
														  VerbOptionsViewController_Phone * optionsViewController = [[VerbOptionsViewController_Phone alloc] init];
														  optionsViewController.verbs = @[ _verb ];
														  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:optionsViewController];
														  if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
														  [self presentViewController:navigationController animated:YES completion:NULL];
													  }]];
	
	NSString * noteButton = (_verb.note.length > 0) ? @"Edit Note..." : @"Add Note";
	[alertController addAction:[UIAlertAction actionWithTitle:noteButton style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) {
														  // Show the panel to add/edit note
														  EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
														  editNoteViewController.verb = _verb;
														  
														  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
														  if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
														  [self presentViewController:navigationController animated:YES completion:NULL];
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Share..." style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) { [self shareAction:nil]; }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Listen" style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) { [self listenAction:nil]; }]];
	
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
	
	if (TARGET_IS_IPAD()) {
		alertController.modalPresentationStyle = UIModalPresentationPopover;
		UIPopoverPresentationController * popController = alertController.popoverPresentationController;
		popController.barButtonItem = self.navigationItem.rightBarButtonItem;
	}
	[self presentViewController:alertController animated:YES completion:NULL];
}

#pragma mark - Web view delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
		NSURLRequest * const request = navigationAction.request;
		NSString * const fragment = request.URL.fragment;
		if ([fragment isEqualToString:@"help-infinitive"] ||
			[fragment isEqualToString:@"help-simple-past"] ||
			[fragment isEqualToString:@"help-past-participle"] ||
			[fragment isEqualToString:@"help-definition"] ||
			[fragment isEqualToString:@"help-example"] ||
			[fragment isEqualToString:@"help-composition"] ||
			[fragment isEqualToString:@"help-quote"]) {
			
			HelpViewController * helpViewController = [[HelpViewController alloc] init];
			helpViewController.anchor = fragment;
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
			if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navigationController animated:YES completion:NULL];
			
		} else if ([fragment isEqualToString:@"edit-note"]) {
			EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
			editNoteViewController.verb = _verb;
			
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
			if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navigationController animated:YES completion:NULL];
		}
		decisionHandler(WKNavigationActionPolicyCancel);
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
	[_activityIndicatorView stopAnimating];
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (scrollView.contentSize.height > 0 && scrollView.contentSize.height <= _webView.frame.size.height) {
		scrollView.showsVerticalScrollIndicator = NO;
		scrollView.scrollEnabled = NO; // Disable scrolling when no need (because of top inset, it always scrolls; 2 hours spent finding that...)
		scrollView.contentOffset = CGPointMake(0, -scrollView.contentInset.top);
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return nil; // Disable zooming
}

- (void)dealloc
{
	_webView.scrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
