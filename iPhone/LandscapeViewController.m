//
//  LandscapeViewController.m
//  iVerb
//
//  Created by Max on 25/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "LandscapeViewController.h"

#import "Playlist+additions.h"

@interface LandscapeViewController ()

@property (nonatomic, strong) UIWebView * webView;

@end

@implementation LandscapeViewController

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
	
	_webView = [[UIWebView alloc] init];
	_webView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:_webView];
	[self.view addConstraints:
  @[ [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTopMargin relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeRight multiplier:1 constant:0],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual
									 toItem:_webView attribute:NSLayoutAttributeBottom multiplier:1 constant:0] ]];
	
	Playlist * currentPlaylist = [Playlist playlistForAction:PlaylistActionSelect];
	if (currentPlaylist.verbs.count == 0) {
		currentPlaylist = [Playlist bookmarksPlaylist];
	}
	NSString * source = [currentPlaylist HTMLFormat];
	[_webView loadHTMLString:source
					 baseURL:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
