//
//  HelpViewController.h
//  iVerb
//
//  Created by Max on 08/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView * webView;
@property (nonatomic, strong) NSString * anchor;

- (IBAction)doneAction:(id)sender;

@end
