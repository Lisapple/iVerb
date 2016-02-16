//
//  ResultViewController.m
//  iVerb
//
//  Created by Max on 9/12/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import "ResultViewController.h"

#import "ManagedObjectContext.h"

#import "VerbOptionsViewController_Phone.h"
#import "HelpViewController.h"
#import "EditNoteViewController.h"

@interface ResultViewController ()
{
	id reloadObserver;
    AVSpeechSynthesizer * synthesizer;
}
@end

@implementation ResultViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSString * infinitif = _verb.infinitif;
	self.title = [@"To " stringByAppendingString:infinitif];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(showOptionAction:)];
	_webView.delegate = self;
	
	NSString * basePath = [NSBundle mainBundle].bundlePath;
	[_webView loadHTMLString:_verb.HTMLFormat
					 baseURL:[NSURL fileURLWithPath:basePath]];
	[_activityIndicatorView startAnimating];
    
    reloadObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"ResultDidReloadNotification"
                                                                       object:nil
                                                                        queue:[NSOperationQueue currentQueue]
                                                                   usingBlock:^(NSNotification *note) {
                                                                       NSString * basePath = [NSBundle mainBundle].bundlePath;
                                                                       [_webView loadHTMLString:_verb.HTMLFormat
                                                                                        baseURL:[NSURL fileURLWithPath:basePath]];
                                                                   }];
}

- (void)setVerb:(Verb *)verb
{
	_verb = verb;
	
	/* Update the verb from the history */
	_verb.lastUse = [NSDate date];
	[_verb addToPlaylist:[Playlist historyPlaylist]];
}

- (void)listenAction:(id)sender
{
	NSString * string = [NSString stringWithFormat:@"to %@, %@, %@", _verb.infinitif, _verb.past, _verb.pastParticiple];
	if ([_verb.infinitif isEqualToString:_verb.past] && [_verb.infinitif isEqualToString:_verb.pastParticiple])
		string = [NSString stringWithFormat:@"to %@", _verb.infinitif];
	
	synthesizer = [[AVSpeechSynthesizer alloc] init];
	AVSpeechUtterance * utterance = [AVSpeechUtterance speechUtteranceWithString:string];
	utterance.rate = 0.1;
	[synthesizer speakUtterance:utterance];
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
			[addActions addObject:[UIPreviewAction actionWithTitle:NSLocalizedString(playlist.name, nil)
														  style:UIPreviewActionStyleDefault
														   handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
															   [playlist addVerb:_verb];
														   }]];
		}
	}
	
	UIPreviewActionGroup * addToAction = [UIPreviewActionGroup actionGroupWithTitle:@"Add to list..."
																			  style:UIPreviewActionStyleDefault
																			actions:addActions];
	
	UIPreviewAction * listenAction = [UIPreviewAction actionWithTitle:@"Listen" style:UIPreviewActionStyleDefault
															  handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
																  [self listenAction:nil]; }];
	
	UIPreviewAction * copyAction = [UIPreviewAction actionWithTitle:@"Copy" style:UIPreviewActionStyleDefault
															  handler:^(UIPreviewAction * action, UIViewController * previewViewController) {
																  [self copyAction:nil]; }];
	
	NSMutableArray <id <UIPreviewActionItem>> * actions = @[ listenAction, copyAction ].mutableCopy;
	if (addActions.count)
		[actions insertObject:addToAction atIndex:0];
	
	return actions;
}

- (IBAction)showOptionAction:(id)sender
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Add to list..." style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) {
														  double delayInSeconds = 0.5;
														  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
														  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
															  VerbOptionsViewController_Phone * optionsViewController = [[VerbOptionsViewController_Phone alloc] init];
															  optionsViewController.verbs = @[ _verb ];
															  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:optionsViewController];
															  [self presentViewController:navigationController animated:YES completion:NULL];
														  });
													  }]];
	
	NSString * noteButton = (_verb.note.length > 0) ? @"Edit Note" : @"Add Note";
	[alertController addAction:[UIAlertAction actionWithTitle:noteButton style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) {
														  // Show the panel to add/edit note
														  EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
														  editNoteViewController.verb = _verb;
														  
														  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
														  [self presentViewController:navigationController animated:YES completion:NULL];
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Listen" style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) { [self listenAction:nil]; }]];
	
	[alertController addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction * action) { [self copyAction:nil]; }]];
	
	if ([MFMailComposeViewController canSendMail]) {
		[alertController addAction:[UIAlertAction actionWithTitle:@"Mail" style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {
															  MFMailComposeViewController * mailCompose = [[MFMailComposeViewController alloc] init];
															  mailCompose.mailComposeDelegate = self;
															  [mailCompose setSubject:[NSString stringWithFormat:@"Forms of \"%@\" from iVerb", _verb.infinitif]];
															  [mailCompose setMessageBody:_verb.HTMLFormatInlineCSS isHTML:YES];
															  [self presentViewController:mailCompose animated:YES completion:NULL];
														  }]];
	}
	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
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
            [self presentViewController:navigationController animated:YES completion:NULL];
            
        } else if ([request.URL.fragment isEqualToString:@"edit-note"]) {
            EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
            editNoteViewController.verb = _verb;
            
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
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
    [[NSNotificationCenter defaultCenter] removeObserver:reloadObserver];
}

@end
