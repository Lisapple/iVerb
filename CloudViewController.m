//
//  CloudViewController.m
//  iVerb
//
//  Created by Max on 05/02/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "CloudViewController.h"
#import "ResultViewController.h"

#import "Playlist.h"

#import "CloudView.h"

#import "UIView+addition.h"

@interface CloudViewController ()

@property (nonatomic, strong) CADisplayLink * link;
@property (nonatomic, strong) NSArray * verbs;

@property (nonatomic, strong) CloudView * cloudView;

@end

@implementation CloudViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Cloud";
	self.view.backgroundColor = [UIColor whiteColor];
	self.view.clipsToBounds = YES;
	
	if (TARGET_IS_IPAD()) {
		// Add a "Done" button on iPad
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self action:@selector(doneAction:)];
	}
	
	const CGFloat parallaxExtraMargin = 30; // Extra margin for parallax effect
	_cloudView = [[CloudView alloc] init];
	_cloudView.translatesAutoresizingMaskIntoConstraints = NO;
	_cloudView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:_cloudView];
	[self.view addConstraints:
  @[ [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
									 toItem:_cloudView attribute:NSLayoutAttributeTop multiplier:1 constant:-parallaxExtraMargin],
	 [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
									 toItem:_cloudView attribute:NSLayoutAttributeLeft multiplier:1 constant:-parallaxExtraMargin],
	 [NSLayoutConstraint constraintWithItem:_cloudView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
									 toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-parallaxExtraMargin],
	 [NSLayoutConstraint constraintWithItem:_cloudView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
									 toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-parallaxExtraMargin] ]];
	
	__block float x = 0.; __block int index = 0;
	__block float * oldYs = (float *)calloc(3, sizeof(float));
	const CGFloat viewHeight = TARGET_IS_IPAD() ? self.view.frame.size.height : [UIScreen mainScreen].bounds.size.height;
	const CGFloat height = viewHeight - (44/*navigation bar*/ + parallaxExtraMargin + 2*20/*top and bottom margins*/);
	
	NSSet * verbsSet = [Playlist allVerbsPlaylist].verbs;
	[verbsSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		
		NSString * infinitif = ((Verb *)obj).infinitif;
		
		CGFloat fontSizes[] = { 24, 18, 14 };
		UIFont * font = [UIFont systemFontOfSize:fontSizes[(index % 3)]];
		CGSize size = [infinitif sizeWithAttributes:@{ NSFontAttributeName : font }];
		size.width += 8.;
		
		float y = 0;
		do { y = (int)((rand() / (float)RAND_MAX) * height) + parallaxExtraMargin; }
		while (ABS(y - oldYs[0]) < 60. || ABS(y - oldYs[1]) < 60. || ABS(y - oldYs[2]) < 60.);
		
		/* Switch older "y" values */
		oldYs[2] = oldYs[1];
		oldYs[1] = oldYs[0];
		oldYs[0] = y;
		
		CGRect frame = CGRectMake(x, y, size.width, size.height);
		CloudLabel * label = [[CloudLabel alloc] initWithFrame:frame];
		label.origin = frame.origin;
		label.verb = (Verb *)obj;
		
		label.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
		label.layer.cornerRadius = 4;
		label.clipsToBounds = YES;
		
		label.textColor = [UIColor darkGrayColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.font = font;
		label.text = infinitif;
		
		BOOL isIncreaseContrastEnabled = (UIAccessibilityIsReduceTransparencyEnabled() || UIAccessibilityDarkerSystemColorsEnabled());
		if (!isIncreaseContrastEnabled) {
			label.alpha = 1. - (index % 3) / 3.;
			
			NSShadow * shadow = [[NSShadow alloc] init];
			shadow.shadowBlurRadius = (index % 3) * 1.5;
			shadow.shadowColor = [UIColor colorWithWhite:0 alpha:.5];
			
			NSDictionary * attributes = @{ NSShadowAttributeName : shadow };
			label.attributedText = [[NSAttributedString alloc] initWithString:infinitif
																   attributes:attributes];
		} else {
			label.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
			label.text = infinitif;
		}
		
		[_cloudView addSubview:label];
		
		x += (int)(size.width / 2.);
		
		++index;
	}];
	free(oldYs); oldYs = NULL;
	
	_cloudView.totalWidth = x - self.view.frame.size.width;
	[_cloudView addParallaxEffect:(ParallaxAxisVertical | ParallaxAxisHorizontal) offset:30];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(labelDidSelected:)
												 name:CloudLabelDidSelectedNotification object:nil];
}

- (void)labelDidSelected:(NSNotification *)notification
{
	Verb * verb = (Verb *)notification.object;
	
	if (TARGET_IS_IPAD()) {
		
		/* Dismiss the view */
		[self dismissViewControllerAnimated:YES completion:NULL];
		
		/* Send a notification to select the verb on webView */
		[[NSNotificationCenter defaultCenter] postNotificationName:SearchTableViewDidSelectCellNotification object:verb];
	} else {
		/* Push the result view controller with the selected verb */
		ResultViewController * resultViewController = [[ResultViewController alloc] init];
		resultViewController.verb = verb;
		[self.navigationController pushViewController:resultViewController animated:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	_link = [CADisplayLink displayLinkWithTarget:_cloudView selector:@selector(update)];
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _link.paused = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _link.paused = YES;
    [_link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

/* Action to close the view controller on iPad */
- (IBAction)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.navigationController.delegate = nil;
}

@end
