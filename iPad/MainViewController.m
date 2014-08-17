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

#define kPinchOutScale 1. + 1./3.
#define kPinchInScale 1. - 1./3.

@implementation MainViewController

@synthesize object;

#pragma mark - View lifecycle

- (void)webviewDidZoomIn:(UIGestureRecognizer *)recognizer
{
	NSDebugLog(@"webviewDidZoomIn");
	[recognizer.view removeGestureRecognizer:recognizer];
	
	Playlist * playlist = [verb.playlists allObjects][0];
	[webView loadHTMLString:playlist.HTMLFormat
					baseURL:nil];
	
	[UIView animateWithDuration:0.5
					 animations:^{
						 leftNavigationController.view.transform = CGAffineTransformMakeTranslation(-leftNavigationController.view.frame.size.width, 0.);
						 navigationBar2.transform = navigationBar.transform = CGAffineTransformMakeTranslation(0., -66.);
                         
                         originalWebViewFrame = webView.frame;
                         CGRect frame = self.view.bounds;
                         frame.origin.y = 20.;
                         frame.size.height -= 20.;
                         webView.frame = frame;
					 }
					 completion:^(BOOL finished) {
						 UIPinchGestureRecognizer * gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
																										action:@selector(webviewDidZoomOut:)];
						 gesture.scale = kPinchInScale;
						 [webView addGestureRecognizer:gesture];
					 }];
}

- (void)webviewDidZoomOut:(UIGestureRecognizer *)recognizer
{
	NSDebugLog(@"webviewDidZoomOut");
	[recognizer.view removeGestureRecognizer:recognizer];
	
	NSString * basePath = [[NSBundle mainBundle] bundlePath];
    [webView loadHTMLString:verb.HTMLFormat
                    baseURL:[NSURL fileURLWithPath:basePath]];
	
	[UIView animateWithDuration:0.5
					 animations:^{
						 leftNavigationController.view.transform = CGAffineTransformIdentity;
						 navigationBar2.transform =navigationBar.transform = CGAffineTransformIdentity;
						 
						 webView.frame = originalWebViewFrame;
					 }
					 completion:^(BOOL finished) {
						 UIPinchGestureRecognizer * gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
																										action:@selector(webviewDidZoomIn:)];
						 gesture.scale = kPinchOutScale;
						 [webView addGestureRecognizer:gesture];
					 }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	verb = [Verb lastUsedVerb];
	if (!verb) {
		Playlist * lastUsedPlaylist = [Playlist lastUsedPlaylist];
		NSArray * verbs = [lastUsedPlaylist.verbs allObjects];
		if (verbs.count > 0) {
			verb = verbs[0];
		} else {
			verb = [[Playlist allVerbsPlaylist].verbs allObjects][0];
		}
	}
	[self refreshWebview];
    
    NSString * title = [NSString stringWithFormat:@"To %@", verb.infinitif];
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
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(showOptionsAction:)];
	/* Add items from "self.navigationController" to "navigationBar" */
	navigationBar.items = @[self.navigationItem];
	
	webView.delegate = self;
    
	UIPinchGestureRecognizer * gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
																				   action:@selector(webviewDidZoomIn:)];
	gesture.scale = kPinchOutScale;
	[webView addGestureRecognizer:gesture];
	
	PlaylistsViewController * playlistsViewController = [[PlaylistsViewController alloc] init];
	leftNavigationController = [[UINavigationController alloc] initWithRootViewController:playlistsViewController];
	leftNavigationController.view.frame = leftContainerView.bounds;
	leftNavigationController.title = @"Search";
	[leftContainerView addSubview:leftNavigationController.view];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"SearchTableViewDidSelectCellNotification"
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  verb = (Verb *)note.object;
													  [self refreshWebview];
                                                      
                                                      /* Update the verb from the history */
                                                      verb.lastUse = [NSDate date];
                                                      [verb addToPlaylist:[Playlist historyPlaylist]];
												  }];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"ResultDidReloadNotification"
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  NSString * basePath = [[NSBundle mainBundle] bundlePath];
													  [webView loadHTMLString:verb.HTMLFormat
																	  baseURL:[NSURL fileURLWithPath:basePath]];
												  }];
}

- (void)refreshWebview
{
	NSString * infinitif = [verb valueForKey:@"infinitif"];
	self.title = [@"To " stringByAppendingString:infinitif];
	
	NSString * basePath = [[NSBundle mainBundle] bundlePath];
	[webView loadHTMLString:verb.HTMLFormat
					baseURL:[NSURL fileURLWithPath:basePath]];
}

- (IBAction)showOptionsAction:(id)sender
{
	if (!showingOptions && !showingLists) {
		NSString * noteButton = (verb.note.length > 0) ? @"Edit Note" : @"Add Note";
		NSString * mail = ([MFMailComposeViewController canSendMail]) ? @"Mail" : nil;
		UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																  delegate:self
														 cancelButtonTitle:@"Cancel"
													destructiveButtonTitle:nil
														 otherButtonTitles:@"Add to list...", noteButton, @"Listen", @"Copy", mail, nil];
		[actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:NO];
		showingOptions = YES;
	}
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0: { // "Add to list..."
			double delayInSeconds = .25;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				VerbOptionsViewController_Pad * verbOptionsViewController = [[VerbOptionsViewController_Pad alloc] init];
				verbOptionsViewController.verbs = @[verb];
				popoverController = [[UIPopoverController alloc] initWithContentViewController:verbOptionsViewController];
				popoverController.delegate = self;
				
				CGSize contentSize = popoverController.popoverContentSize;
				contentSize.height = verbOptionsViewController.tableView.contentSize.height;
				popoverController.popoverContentSize = contentSize;
				
				[popoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
										  permittedArrowDirections:UIPopoverArrowDirectionUp
														  animated:NO];
				
				showingLists = YES;
			});
		}
			break;
		case 1: { // "Add/Edit Note"
			/* Show the panel to add/edit note */
			EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
			editNoteViewController.verb = verb;
			
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
			navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navigationController animated:YES completion:NULL];
		}
			break;
		case 2: { // "Listen"
			
			NSURL * fileURL = [[NSBundle mainBundle] URLForResource:verb.infinitif withExtension:@"mp3" subdirectory:@"Sounds"];
			NSError * error = nil;
			player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
			if (error) NSDebugLog(@"error: %@", error);
			
			[player prepareToPlay];
			if ([player play]) NSDebugLog(@"Playing...");
			
		}
			break;
		case 3: { // "Copy"
			/* Copy to pasteboard ("Infinitif\nSimple Past\nPP\nDefinition\nNote") */
			NSString * note = (verb.note.length > 0)? [NSString stringWithFormat:@"\n%@\n", verb.note] : @"";
			NSString * body = [NSString stringWithFormat:@"%@\n%@\n%@\n%@%@", verb.infinitif, verb.past, verb.pastParticiple, verb.definition, note];
			
			UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = body;
		}
			break;
		case 4: { // "Mail"
			MFMailComposeViewController * mailCompose = [[MFMailComposeViewController alloc] init];
			mailCompose.mailComposeDelegate = self;
			[mailCompose setSubject:[NSString stringWithFormat:@"Forms of \"%@\" from iVerb", verb.infinitif]];
			[mailCompose setMessageBody:verb.HTMLFormatInlineCSS isHTML:YES];
			[self presentViewController:mailCompose animated:YES completion:NULL];
		}
			break;
            default: // "Cancel"
			break;
	}
	
	showingOptions = NO;
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
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController
{
	showingOptions = NO;
	showingLists = NO;
	popoverController = nil;
}

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL.fragment isEqualToString:@"help-infinitive"] ||
            [request.URL.fragment isEqualToString:@"help-simple-past"] ||
            [request.URL.fragment isEqualToString:@"help-past-participle"] ||
            [request.URL.fragment isEqualToString:@"help-definition"] ||
            [request.URL.fragment isEqualToString:@"help-example"] ||
            [request.URL.fragment isEqualToString:@"help-composition"]) {
            
            HelpViewController * helpViewController = [[HelpViewController alloc] init];
            helpViewController.anchor = request.URL.fragment;
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navigationController animated:YES completion:NULL];
            
        } else if ([request.URL.fragment isEqualToString:@"edit-note"]) {
            
            EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
            editNoteViewController.verb = verb;
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navigationController animated:YES completion:NULL];
        }
        
        /* Reload the webView from stratch (not by calling "-[UIWebView reload]") */
		double delayInSeconds = 1.;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			
			NSString * basePath = [[NSBundle mainBundle] bundlePath];
			[webView loadHTMLString:verb.HTMLFormat
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

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
