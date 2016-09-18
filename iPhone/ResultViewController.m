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

@interface ResultViewController ()

@property (nonatomic, strong) AVSpeechSynthesizer * synthesizer;

@end

@implementation ResultViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSString * infinitif = _verb.infinitif;
	self.title = [@"To " stringByAppendingString:infinitif];
	
	self.navigationItem.rightBarButtonItems = @[ [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																							   target:self
																							   action:@selector(showOptionAction:)],
												 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"favorite"]
																				  style:UIBarButtonItemStylePlain
																				 target:self action:@selector(tooggleFavoriteAction:)] ];
	
	NSString * basePath = [NSBundle mainBundle].bundlePath;
	[_webView loadHTMLString:_verb.HTMLFormat
					 baseURL:[NSURL fileURLWithPath:basePath]];
	_webView.delegate = self;
	[_activityIndicatorView startAnimating];
    
	[[NSNotificationCenter defaultCenter] addObserverForName:ResultDidReloadNotification
													  object:nil queue:nil
												  usingBlock:^(NSNotification * notification) {
													  NSString * basePath = [NSBundle mainBundle].bundlePath;
													  [_webView loadHTMLString:_verb.HTMLFormat
																	   baseURL:[NSURL fileURLWithPath:basePath]];
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
														  NSString * basePath = [NSBundle mainBundle].bundlePath;
														  [_webView loadHTMLString:_verb.HTMLFormat
																		   baseURL:[NSURL fileURLWithPath:basePath]];
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

- (void)copyAction:(id)sender
{
	// Copy to pasteboard: "Infinitif\nSimple Past\nPP\nDefinition\nNote"
	NSString * note = (_verb.note.length > 0)? [NSString stringWithFormat:@"\n%@\n", _verb.note] : @"";
	NSString * body = [NSString stringWithFormat:@"%@\n%@\n%@\n%@%@", _verb.infinitif, _verb.past, _verb.pastParticiple, _verb.definition, note];
	
	UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = body;
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
	
	UIPreviewAction * copyAction = [UIPreviewAction actionWithTitle:@"Copy" style:UIPreviewActionStyleDefault
															  handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
																  [self copyAction:nil]; }];
	
	NSMutableArray <id <UIPreviewActionItem>> * actions = @[ listenAction, copyAction ].mutableCopy;
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
	
	NSString * noteButton = (_verb.note.length > 0) ? @"Edit Note" : @"Add Note";
	[alertController addAction:[UIAlertAction actionWithTitle:noteButton style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) {
														  // Show the panel to add/edit note
														  EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
														  editNoteViewController.verb = _verb;
														  
														  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
														  if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
														  [self presentViewController:navigationController animated:YES completion:NULL];
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Listen" style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) { [self listenAction:nil]; }]];
	
	[alertController addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) { [self copyAction:nil]; }]];
	
	if ([MFMailComposeViewController canSendMail]) {
		[alertController addAction:[UIAlertAction actionWithTitle:@"Send with Mail" style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {
															  MFMailComposeViewController * mailCompose = [[MFMailComposeViewController alloc] init];
															  mailCompose.mailComposeDelegate = self;
															  [mailCompose setSubject:[NSString stringWithFormat:@"Forms of \"%@\" from iVerb", _verb.infinitif]];
															  [mailCompose setMessageBody:_verb.HTMLFormatInlineCSS isHTML:YES];
															  [self presentViewController:mailCompose animated:YES completion:NULL];
														  }]];
	}
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
	
	if (TARGET_IS_IPAD()) {
		alertController.modalPresentationStyle = UIModalPresentationPopover;
		UIPopoverPresentationController * popController = alertController.popoverPresentationController;
		popController.barButtonItem = self.navigationItem.rightBarButtonItem;
	}
	[self presentViewController:alertController animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if (error) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error when sending mail"
																				 message:error.localizedDescription
																		  preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
		[self presentViewController:alertController animated:YES completion:NULL];
	}
	
	[controller dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Web view delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL.fragment isEqualToString:@"help-infinitive"] ||
            [request.URL.fragment isEqualToString:@"help-simple-past"] ||
            [request.URL.fragment isEqualToString:@"help-past-participle"] ||
            [request.URL.fragment isEqualToString:@"help-definition"] ||
            [request.URL.fragment isEqualToString:@"help-example"] ||
            [request.URL.fragment isEqualToString:@"help-composition"] ||
			[request.URL.fragment isEqualToString:@"help-quote"]) {
            
            HelpViewController * helpViewController = [[HelpViewController alloc] init];
            helpViewController.anchor = request.URL.fragment;
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
			if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navigationController animated:YES completion:NULL];
            
        } else if ([request.URL.fragment isEqualToString:@"edit-note"]) {
            EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
            editNoteViewController.verb = _verb;
            
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
			if (TARGET_IS_IPAD()) navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navigationController animated:YES completion:NULL];
        }
        
        // Reload the webView from stratch (not by calling "-[UIWebView reload]")
		double delayInSeconds = 1.;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			NSString * basePath = [NSBundle mainBundle].bundlePath;
			[_webView loadHTMLString:_verb.HTMLFormat
							 baseURL:[NSURL fileURLWithPath:basePath]];
		});
        return NO;
    }
    
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[_activityIndicatorView stopAnimating];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
