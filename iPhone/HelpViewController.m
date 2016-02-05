//
//  HelpViewController.m
//  iVerb
//
//  Created by Max on 08/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "HelpViewController.h"

@implementation HelpViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor purpleColor];
    
	self.title = @"Help";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneAction:)];
	_webView.delegate = self;
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
	NSString * content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	NSString * basePath = [NSBundle mainBundle].bundlePath;
	[_webView loadHTMLString:content
					 baseURL:[NSURL fileURLWithPath:basePath]];
}

- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Web view delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		/* Open with Safari */
        if ([[UIApplication sharedApplication] canOpenURL:request.URL] && ![request.URL.scheme isEqualToString:@"file"]) {
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
	}
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"location.hash = '%@'", _anchor]];
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

@end
