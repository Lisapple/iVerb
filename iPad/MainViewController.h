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

#import "IVWebView.h"

#import "Verb.h"
#import "Verb+additions.h"

#import "Playlist+additions.h"

@interface MainViewController : UIViewController
<UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
	@private
	CGRect originalWebViewFrame;
	BOOL showingLists;
	
	UIPopoverPresentationController * popoverController;
	
	AVSpeechSynthesizer * synthesizer;
}

@property (nonatomic, strong) NSManagedObject * object;
@property (nonatomic, strong) Verb * verb;

@property (nonatomic, assign) IBOutlet IVWebView * webView;
@property (nonatomic, assign) IBOutlet UINavigationBar * navigationBar, * navigationBar2;

@property (nonatomic, strong) UINavigationController * leftNavigationController;
@property (nonatomic, assign) IBOutlet UIView * leftContainerView;

- (IBAction)showOptionsAction:(id)sender;

- (void)refreshWebview;

@end
