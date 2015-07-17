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
	
	Playlist * currentPlaylist = [Playlist currentPlaylist];
	NSString * source = [currentPlaylist HTMLFormat];
	[_webView loadHTMLString:source
					 baseURL:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
