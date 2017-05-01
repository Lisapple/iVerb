//
//  HelpViewController.m
//  iVerb
//
//  Created by Max on 08/02/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "HelpViewController.h"
#import "UIApplication+addition.h"

#import "UIColor+addition.h"

@interface HelpViewController ()

@property (nonatomic, strong) WKWebView * webView;

- (IBAction)doneAction:(id)sender;

@end

@implementation HelpViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor foregroundColor];
    
	self.title = @"Help";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self action:@selector(doneAction:)];
	
	WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc] init];
	_webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
	_webView.translatesAutoresizingMaskIntoConstraints = NO;
	_webView.navigationDelegate = self;
	_webView.scrollView.delegate = self;
	[self.view addSubview:_webView];
	[self.view addConstraints:
  @[ [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeRight multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeBottom multiplier:1 constant:0] ]];
	
	NSString * path = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
	NSMutableString * content = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
	[content replaceOccurrencesOfString:@"{{font-size}}" withString:[NSString stringWithFormat:@"%ldpx", (long)fontSize]
								options:0 range: NSMakeRange(0, content.length)];
	NSString * basePath = [NSBundle mainBundle].bundlePath;
	[_webView loadHTMLString:content baseURL:[NSURL fileURLWithPath:basePath]];
}

- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Web view delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
		[[UIApplication sharedApplication] openExternalURL:navigationAction.request.URL];
		decisionHandler(WKNavigationActionPolicyCancel);
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
	NSString * javascript = [NSString stringWithFormat:@"location.hash = '%@'", _anchor];
	[_webView evaluateJavaScript:javascript completionHandler:nil];
}

#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return nil; // Disable zooming
}

- (BOOL)shouldAutorotate
{
	return (TARGET_IS_IPAD());
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return (TARGET_IS_IPAD())? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc
{
	_webView.scrollView.delegate = nil;
}

@end
