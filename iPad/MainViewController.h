//
//  MainViewController.h
//  iVerb
//
//  Created by Max on 21/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>

#import "Verb.h"
#import "Verb+additions.h"

#import "Playlist+additions.h"

@interface MainViewController : UIViewController <UIPopoverControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
	IBOutlet UIWebView * webView;
	IBOutlet UINavigationBar * navigationBar;
	
	IBOutlet UINavigationController * leftNavigationController;
	IBOutlet UIView * leftContainerView;
	
	NSManagedObject * object;
	Verb * verb;
	
	@private
	CGRect originalWebViewFrame;
	BOOL showingOptions, showingLists;
	
	UIPopoverController * popoverController;
	
	AVAudioPlayer * player;
}

@property (nonatomic, strong) NSManagedObject * object;

- (IBAction)showOptionsAction:(id)sender;

- (void)refreshWebview;

@end
