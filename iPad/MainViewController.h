//
//  MainViewController.h
//  iVerb
//
//  Created by Max on 21/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreData;
@import MessageUI;
@import AVFoundation;

#import "IVWebView.h"

#import "Verb.h"
#import "Verb+additions.h"

#import "Playlist+additions.h"

@interface MainViewController : UISplitViewController
	<UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate>

@end
