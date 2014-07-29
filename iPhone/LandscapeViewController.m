//
//  LandscapeViewController.m
//  iVerb
//
//  Created by Max on 25/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "LandscapeViewController.h"

#import "Playlist+additions.h"

@implementation LandscapeViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    /*
	CGRect frame = self.view.bounds;
	frame.origin.y -= kTopMargin;
	frame.size.height += kTopMargin * 2.;
	_webView.frame = frame;
	
	if ([_webView respondsToSelector:@selector(scrollView)]) 
		_webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(kTopMargin, 0., kTopMargin, 0.);
	else {
		UIScrollView * scrollView = (_webView.subviews)[0];
		scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(kTopMargin, 0., kTopMargin, 0.);
	}
    */
	
	Playlist * currentPlaylist = [Playlist currentPlaylist];
	NSString * source = [currentPlaylist HTMLFormat];
	[_webView loadHTMLString:source
					 baseURL:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
