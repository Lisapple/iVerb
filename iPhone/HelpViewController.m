//
//  HelpViewController.m
//  iVerb
//
//  Created by Max on 08/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "HelpViewController.h"

//#import "UIBarButtonItem+addition.h"

@implementation HelpViewController

@synthesize webView = _webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.tintColor = [UIColor purpleColor];
    
	self.title = @"Help";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneAction:)];
	/*
     CGRect frame = _webView.frame;
     frame.origin.y = 44. - kTopMargin;
     frame.size.height = _webView.frame.size.height + (kTopMargin * 2. - 44.);
     _webView.frame = frame;
     
     if ([_webView respondsToSelector:@selector(scrollView)])
     _webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(kTopMargin, 0., kTopMargin, 0.);
     else {
     UIScrollView * scrollView = [_webView.subviews objectAtIndex:0];
     scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(kTopMargin, 0., kTopMargin, 0.);
     }
     */
    
	_webView.delegate = self;
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
	NSString * content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	NSString * basePath = [[NSBundle mainBundle] bundlePath];
	[_webView loadHTMLString:content
					 baseURL:[NSURL fileURLWithPath:basePath]];
}

- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIWebView Delegate

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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIDeviceOrientationIsLandscape(interfaceOrientation) || UIDeviceOrientationIsPortrait(interfaceOrientation));
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (NSUInteger)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationPortrait;
}

@end
