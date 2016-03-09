//
//  MainViewController.m
//  iVerb
//
//  Created by Max on 21/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainViewController.h"

#import "PlaylistsViewController.h"
#import "HelpViewController.h"
#import "EditNoteViewController.h"
#import "ResultViewController.h"
#import "SearchViewController.h"
#import "WebViewController.h"

@implementation MainViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
	
	// Left navigation controller
	PlaylistsViewController * playlistsViewController = [[PlaylistsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController * leftNavigationController = (UINavigationController *)self.viewControllers.firstObject;
	[leftNavigationController pushViewController:playlistsViewController animated:NO];
	
	SearchViewController * searchViewController = [[SearchViewController alloc] init];
	searchViewController.playlist = [Playlist playlistForAction:PlaylistActionSelect];
	[leftNavigationController pushViewController:searchViewController animated:NO];
	
	// Right navigation controller
	Verb * verb = [Verb lastUsedVerb];
	if (!verb) {
		verb = [Playlist playlistForAction:PlaylistActionSelect].verbs.anyObject;
		if (!verb)
			verb = [Playlist allVerbsPlaylist].verbs.anyObject;
	}
	ResultViewController * resultViewController = [[ResultViewController alloc] init];
	resultViewController.verb = verb;
	UINavigationController * rightNavigationController = (UINavigationController *)self.viewControllers.lastObject;
	[rightNavigationController pushViewController:resultViewController animated:NO];
	
	resultViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"fullscreen"]
																							 style:UIBarButtonItemStylePlain
																							target:self action:@selector(enterFullscreenAction:)];
}

- (void)enterFullscreenAction:(id)sender
{
	NSString * name = [NSBundle mainBundle].infoDictionary[@"UIMainStoryboardFile"];
	WebViewController * webViewController = [[UIStoryboard storyboardWithName:name bundle:nil] instantiateViewControllerWithIdentifier:@"WebViewController"];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
	
	Playlist * playlist = [Playlist playlistForAction:PlaylistActionSelect];
	webViewController.title = playlist.localizedName;
	
	// Show "Done" button to exit fullscreen mode
	webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						 target:self action:@selector(exitFullscreenAction:)];
	
	[self presentViewController:navigationController animated:YES completion:^{
		NSString * basePath = [NSBundle mainBundle].bundlePath;
		[webViewController.webView loadHTMLString:playlist.HTMLFormat
										  baseURL:[NSURL fileURLWithPath:basePath]];
	}];
}

- (void)exitFullscreenAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

@end
