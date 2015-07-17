//
//  ResultViewController.h
//  iVerb
//
//  Created by Max on 9/12/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>

#import "IVViewController.h"
#import "IVWebView.h"

#import "Playlist.h"
#import "Verb.h"
#import "Verb+additions.h"

@interface ResultViewController : IVViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSString * verbString;
@property (nonatomic, strong) Verb * verb;

@property (nonatomic, unsafe_unretained) IBOutlet IVWebView * webView;

@property (nonatomic, unsafe_unretained) IBOutlet UILabel * infinitiveLabel, * pastLabel, * participleLabel, * translationLabel;
@property (nonatomic, unsafe_unretained) IBOutlet UIImageView * bookmarkImageView;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicatorView;

@end
