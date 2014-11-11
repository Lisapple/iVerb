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
}
@end

@implementation ResultViewController

@synthesize verbString = _verbString;
@synthesize verb = _verb;

@synthesize webView = _webView;

@synthesize infinitiveLabel = _infinitiveLabel, pastLabel = _pastLabel, participleLabel = _participleLabel, translationLabel = _translationLabel;
@synthesize bookmarkImageView = _bookmarkImageView;

@synthesize activityIndicatorView = _activityIndicatorView;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSString * infinitif = _verb.infinitif;
	self.title = [@"To " stringByAppendingString:infinitif];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(showOptionAction:)];
	_webView.delegate = self;
	
	NSString * basePath = [[NSBundle mainBundle] bundlePath];
	[_webView loadHTMLString:_verb.HTMLFormat
					 baseURL:[NSURL fileURLWithPath:basePath]];
	[_activityIndicatorView startAnimating];
    
    reloadObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"ResultDidReloadNotification"
                                                                       object:nil
                                                                        queue:[NSOperationQueue currentQueue]
                                                                   usingBlock:^(NSNotification *note) {
                                                                       NSString * basePath = [[NSBundle mainBundle] bundlePath];
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

- (IBAction)showOptionAction:(id)sender
{
	NSString * noteButton = (_verb.note.length > 0) ? @"Edit Note" : @"Add Note";
	NSString * mail = ([MFMailComposeViewController canSendMail]) ? @"Mail" : nil;
	ActionSheet * actionSheet = [[ActionSheet alloc] initWithTitle:nil
														  delegate:self
												 cancelButtonTitle:@"Cancel"
											destructiveButtonTitle:nil
												 otherButtonTitles:@"Add to list...", noteButton, @"Listen", @"Copy", mail, nil];
	actionSheet.delegate = self;
	[actionSheet showInView:self.view];
}

#pragma mark - ActionSheet Delegate

- (void)actionSheet:(ActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0: { // "Add to list..."
			double delayInSeconds = 0.5;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				VerbOptionsViewController_Phone * optionsViewController = [[VerbOptionsViewController_Phone alloc] init];
				optionsViewController.verbs = @[_verb];
				optionsViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
				optionsViewController.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.];
				[self presentViewController:optionsViewController animated:YES completion:NULL];
			});
		}
			break;
		case 1: { // "Add/Edit Note"
			/* Show the panel to add/edit note */
			EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
			editNoteViewController.verb = _verb;
			
			UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
			[self presentViewController:navigationController animated:YES completion:NULL];
		}
			break;
		case 2: { // "Listen"
			
			NSString * string = [NSString stringWithFormat:@"to %@, %@, %@", _verb.infinitif, _verb.past, _verb.pastParticiple];
			if ([_verb.infinitif isEqualToString:_verb.past] && [_verb.infinitif isEqualToString:_verb.pastParticiple])
				string = [NSString stringWithFormat:@"to %@", _verb.infinitif];
			
			synthesizer = [[AVSpeechSynthesizer alloc] init];
			AVSpeechUtterance * utterance = [AVSpeechUtterance speechUtteranceWithString:string];
			utterance.rate = 0.1;
			[synthesizer speakUtterance:utterance];
			
			/*
			NSURL * fileURL = [[NSBundle mainBundle] URLForResource:_verb.infinitif withExtension:@"mp3" subdirectory:@"Sounds"];
			NSError * error = nil;
			player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
			if (error) NSDebugLog(@"error: %@", error);
			
			[player prepareToPlay];
			if ([player play]) NSDebugLog(@"Playing...");
			*/
		}
			break;
		case 3: { // "Copy"
			/* Copy to pasteboard ("Infinitif\nSimple Past\nPP\nDefinition\nNote") */
			NSString * note = (_verb.note.length > 0)? [NSString stringWithFormat:@"\n%@\n", _verb.note] : @"";
			NSString * body = [NSString stringWithFormat:@"%@\n%@\n%@\n%@%@", _verb.infinitif, _verb.past, _verb.pastParticiple, _verb.definition, note];
			
			UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = body;
		}
			break;
		case 4: { // "Mail"
			MFMailComposeViewController * mailCompose = [[MFMailComposeViewController alloc] init];
			mailCompose.mailComposeDelegate = self;
			[mailCompose setSubject:[NSString stringWithFormat:@"Forms of \"%@\" from iVerb", _verb.infinitif]];
			[mailCompose setMessageBody:_verb.HTMLFormatInlineCSS isHTML:YES];
			[self presentViewController:mailCompose animated:YES completion:NULL];
		}
			break;
		default: // "Cancel"
			break;
	}
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

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
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
            [self presentViewController:navigationController animated:YES completion:NULL];
            
        } else if ([request.URL.fragment isEqualToString:@"edit-note"]) {
            EditNoteViewController * editNoteViewController = [[EditNoteViewController alloc] init];
            editNoteViewController.verb = _verb;
            
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editNoteViewController];
            [self presentViewController:navigationController animated:YES completion:NULL];
        }
        
        /* Reload the webView from stratch (not by calling "-[UIWebView reload]") */
		double delayInSeconds = 1.;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			
			NSString * basePath = [[NSBundle mainBundle] bundlePath];
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

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	self.verbString = nil;
	self.verb = nil;
	
	self.webView = nil;
	
	self.infinitiveLabel = nil;
	self.pastLabel = nil;
	self.participleLabel = nil;
	self.translationLabel = nil;
	
	self.bookmarkImageView = nil;
}

@end
