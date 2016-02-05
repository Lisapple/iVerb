//
//  RootNavigationController.m
//  iVerb
//
//  Created by Max on 23/06/15.
//
//

#import "RootNavigationController.h"

@interface RootNavigationController ()
@property (nonatomic, assign) BOOL isLandscapeMode;
@end

@implementation RootNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
	_isLandscapeMode = (size.width > size.height);
	[self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden
{
	return _isLandscapeMode;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	return UIStatusBarAnimationFade;
}

@end
