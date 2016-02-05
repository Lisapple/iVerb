//
//  MainViewController.m
//  iVerb
//
//  Created by Max on 21/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainViewController.h"

#import "PlaylistsViewController.h"
#import "VerbOptionsViewController_Pad.h"
#import "HelpViewController.h"
#import "EditNoteViewController.h"

#define kPinchOutScale (4. / 3.) // 1 + 1/3 = 1,333
#define kPinchInScale  (2. / 3.) // 1 - 1/3 = 0,666

@implementation MainViewController

#pragma mark - View lifecycle

- (void)webviewDidZoomIn:(UIGestureRecognizer *)recognizer
{
	[recognizer.view removeGestureRecognizer:recognizer];
	
	Playlist * playlist = _verb.playlists.anyObject;
	[_webView loadHTMLString:playlist.HTMLFormat
					baseURL:nil];
	
	[UIView animateWithDuration:0.5
					 animations:^{
						 _leftNavigationController.view.transform = CGAffineTransformMakeTranslation(-_leftNavigationController.view.frame.size.width, 0.);
						 _navigationBar2.transform = _navigationBar.transform = CGAffineTransformMakeTranslation(0., -66.);
                         
                         originalWebViewFrame = _webView.frame;
                         CGRect frame = self.view.bounds;
                         frame.origin.y = 20.;
                         frame.size.height -= 20.;
                         _webView.frame = frame;
					 }
					 completion:^(BOOL finished) {
						 UIPinchGestureRecognizer * gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
																										action:@selector(webviewDidZoomOut:)];
						 gesture.scale = kPinchInScale;
						 [_webView addGestureRecognizer:gesture];
					 }];
}

- (void)webviewDidZoomOut:(UIGestureRecognizer *)recognizer
{
	[recognizer.view removeGestureRecognizer:recognizer];
	
	NSString * basePath = [NSBundle mainBundle].bundlePath;
    [_webView loadHTMLString:_verb.HTMLFormat
                    baseURL:[NSURL fileURLWithPath:basePath]];
	
	[UIView animateWithDuration:0.5
					 animations:^{
						 _leftNavigationController.view.transform = CGAffineTransformIdentity;
						 _navigationBar2.transform = _navigationBar.transform = CGAffineTransformIdentity;
						 _webView.frame = originalWebViewFrame;
					 }
					 completion:^(BOOL finished) {
						 UIPinchGestureRecognizer * gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(webviewDidZoomIn:)];
						 gesture.scale = kPinchOutScale;
						 [_webView addGestureRecognizer:gesture];
					 }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_verb = [Verb lastUsedVerb];
	if (!_verb) {
		_verb = [Playlist currentPlaylist].verbs.anyObject;
		if (!_verb)
			_verb = [Playlist allVerbsPlaylist].verbs.anyObject;
	}
	[self refreshWebview];
    
    self.title = [NSString stringWithFormat:@"To %@", _verb.infinitif];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self action:@selector(showOptionsAction:)];
	// Add items from "self.navigationController" to "navigationBar"
	_navigationBar.items = @[self.navigationItem];
	
	_webView.delegate = self;
    
	UIPinchGestureRecognizer * gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(webviewDidZoomIn:)];
	gesture.scale = kPinchOutScale;
	[_webView addGestureRecognizer:gesture];
	
	PlaylistsViewController * playlistsViewController = [[PlaylistsViewController alloc] init];
	_leftNavigationController = [[UINavigationController alloc] initWithRootViewController:playlistsViewController];
	_leftNavigationController.view.frame = _leftContainerView.bounds;
	_leftNavigationController.title = @"Search";
	[_leftContainerView addSubview:_leftNavigationController.view];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:SearchTableViewDidSelectCellNotification object:nil
													   queue:nil usingBlock:^(NSNotification *note) {
													  _verb = (Verb *)note.object;
													  [self refreshWebview];
                                                      
                                                      /* Update the verb from the history */
                                                      _verb.lastUse = [NSDate date];
                                                      [_verb addToPlaylist:[Playlist historyPlaylist]];
												  }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"ResultDidReloadNotification"
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  NSString * basePath = [NSBundle mainBundle].bundlePath;
													  [_webView loadHTMLString:_verb.HTMLFormat
																	  baseURL:[NSURL fileURLWithPath:basePath]];
												  }];
}

- (void)setTitle:(NSString *)title
{
	super.title = title;
	
	UIFont * font = [UIFont boldSystemFontOfSize:20.];
	CGSize size = [title sizeWithAttributes:@{ NSFontAttributeName : font }];
	
	CGRect rect = CGRectMake(0., 0., size.width, 40.);
	UILabel * titleLabel = [[UILabel alloc] initWithFrame:rect];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.text = title;
	titleLabel.font = font;
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.textColor = [UIColor darkGrayColor];
	self.navigationItem.titleView = titleLabel;
}

- (void)refreshWebview
{
	NSString * infinitif = [_verb valueForKey:@"infinitif"];
	self.title = [@"To " stringByAppendingString:infinitif];
	
	NSString * basePath = [NSBundle mainBundle].bundlePath;
	[_webView loadHTMLString:_verb.HTMLFormat
					baseURL:[NSURL fileURLWithPath:basePath]];
}

- (IBAction)showOptionsAction:(id)sender
{
	if (!showingLists) {
		
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Add to list..." style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * __nonnull action) {
															  double delayInSeconds = .25;
															  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
															  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
																  VerbOptionsViewController_Pad * verbOptionsViewController = [[VerbOptionsViewController_Pad alloc] init];
																  verbOptionsViewController.verbs = @[ _verb ];
																  verbOptionsViewController.modalPresentationStyle = UIModalPresentationPopover;

																  popoverController = verbOptionsViewController.popoverPresentationController;
																  popoverController.delegate = self;
																  popoverController.permittedArrowDirections = UIPopoverArrowDirectionUp;
																  [popoverController.containerView sizeToFit];
																  popoverController.barButtonItem = self.navigationItem.rightBarButtonItem;
																  [self presentViewController:verbOptionsViewController animated:NO completion:NULL];
																  
																  showingLists = YES;
															  });
														  }]];
		
		NSString * noteButton = (_verb.note.length > 0) ? @"Edit Note" : @"Add Note";
		[alertController addAction:[UIAlertAction actionWithTitle:noteButton style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * __nonnull action) {
															  /* Show the panel to add/edit note */
															  EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
															  editNoteViewController.verb = _verb;
															  
															  UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
															  navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
															  [self presentViewController:navigationController animated:YES completion:NULL];
														  }]];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Listen" style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * __nonnull action) {
															  NSString * string = [NSString stringWithFormat:@"to %@, %@, %@", _verb.infinitif, _verb.past, _verb.pastParticiple];
															  if ([_verb.infinitif isEqualToString:_verb.past] && [_verb.infinitif isEqualToString:_verb.pastParticiple])
																  string = [NSString stringWithFormat:@"to %@", _verb.infinitif];
															  
															  synthesizer = [[AVSpeechSynthesizer alloc] init];
															  AVSpeechUtterance * utterance = [AVSpeechUtterance speechUtteranceWithString:string];
															  utterance.rate = 0.1;
															  [synthesizer speakUtterance:utterance];
														  }]];
		[alertController addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * __nonnull action) {
															  /* Copy to pasteboard ("Infinitif\nSimple Past\nPP\nDefinition\nNote") */
															  NSString * note = (_verb.note.length > 0)? [NSString stringWithFormat:@"\n%@\n", _verb.note] : @"";
															  NSString * body = [NSString stringWithFormat:@"%@\n%@\n%@\n%@%@", _verb.infinitif, _verb.past, _verb.pastParticiple, _verb.definition, note];
															  
															  UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
															  pasteboard.string = body;
														  }]];
		
		if ([MFMailComposeViewController canSendMail]) {
			[alertController addAction:[UIAlertAction actionWithTitle:@"Mail" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * __nonnull action) {
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
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if (error) {
		UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Error when sending mail"
																				  message:error.localizedDescription
																		   preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:NULL]];
		[self presentViewController:alertController animated:YES completion:NULL];
	}
	
	[controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
	showingLists = NO;
	popoverController = nil;
}

#pragma mark - Web view delegate

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([@[ @"help-infinitive", @"help-simple-past", @"help-past-participle",
				@"help-definition", @"help-example", @"help-composition", @"help-quote" ] containsObject:request.URL.fragment]) {
            
            HelpViewController * helpViewController = [[HelpViewController alloc] init];
            helpViewController.anchor = request.URL.fragment;
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navigationController animated:YES completion:NULL];
            
        } else if ([request.URL.fragment isEqualToString:@"edit-note"]) {
            
            EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
            editNoteViewController.verb = _verb;
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navigationController animated:YES completion:NULL];
        }
        
        /* Reload the webView from stratch (not by calling "-[UIWebView reload]") */
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self refreshWebview];
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
