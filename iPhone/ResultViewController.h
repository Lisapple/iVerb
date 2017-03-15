//
//  ResultViewController.h
//  iVerb
//
//  Created by Max on 9/12/10.
//  Copyright 2010 Lisacintosh. All rights reserved.
//

@import CoreData;
@import MessageUI;
@import AVFoundation;
@import WebKit;

#import "IVWebView.h"

#import "Playlist.h"
#import "Verb.h"
#import "Verb+additions.h"

@interface ResultViewController : UIViewController <WKNavigationDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSString * verbString;
@property (nonatomic, strong) Verb * verb;

@property (nonatomic, assign) IBOutlet IVWebView * webView;

@property (nonatomic, assign) IBOutlet UILabel * infinitiveLabel, * pastLabel, * participleLabel, * translationLabel;
@property (nonatomic, assign) IBOutlet UIImageView * bookmarkImageView;

@property (nonatomic, assign) IBOutlet UIActivityIndicatorView * activityIndicatorView;

@end
