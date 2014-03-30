//
//  AppDelegate_Phone.m
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

#import "AppDelegate_Phone.h"

#import "UIBarButtonItem+addition.h"

#import "LandscapeViewController.h"

@implementation BorderMaskWindow

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	float radius = 26.;
	float lineWidth = 20.;
	
	CGContextMoveToPoint(context, -lineWidth, lineWidth);
	CGContextAddArcToPoint(context, -lineWidth, -lineWidth, 0., -lineWidth, radius);
	CGContextAddArcToPoint(context, rect.size.width + lineWidth, -lineWidth, rect.size.width + lineWidth, 0., radius);
	
	CGContextAddLineToPoint(context, rect.size.width + lineWidth, rect.size.height + lineWidth);
	CGContextAddLineToPoint(context, - lineWidth, rect.size.height + lineWidth);
	CGContextAddLineToPoint(context, -lineWidth, lineWidth);
	CGContextClosePath(context);
	
	CGContextSetLineWidth(context, lineWidth * 2.);
	
	[[UIColor blackColor] setStroke];
	CGContextStrokePath(context);
}

@end

@implementation UINavigationBar (CustomImage)

/*
 - (void)drawRect:(CGRect)rect
 {
 self.tintColor = [UIColor colorWithWhite:0.9 alpha:1.];
 self.translucent = YES;
 }
 */

@end

@implementation UISearchBar (CustomImage)

- (void)drawRect:(CGRect)rect
{
	if (self.subviews.count > 1) {
		[[self.subviews objectAtIndex:0] removeFromSuperview];
	}
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
}

@end


@implementation AppDelegate_Phone

@synthesize window;

@synthesize dictionary;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	CGRect frame = window.frame;
	frame.size.height -= 20.;
	frame.origin.y = 20.;
	borderMaskWindow = [[BorderMaskWindow alloc] initWithFrame:frame];
	borderMaskWindow.backgroundColor = [UIColor clearColor];
	borderMaskWindow.windowLevel = UIWindowLevelStatusBar;
	borderMaskWindow.userInteractionEnabled = NO;
	[borderMaskWindow makeKeyAndVisible];
	
	PlaylistsViewController * playlistsViewController = [[PlaylistsViewController alloc] init];
	
	navigationController = [[UINavigationController alloc] initWithRootViewController:playlistsViewController];
	navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.9 alpha:1.];
	navigationController.navigationBar.translucent = YES;
	
	navigationController.navigationBar.layer.masksToBounds = YES;// Remove the drop shadow on iOS6
	
	window.backgroundColor = [UIColor blackColor];
	window.rootViewController = navigationController;
	
    [window makeKeyAndVisible];
	
	/*** Hack: Disable the sending of notifications when the device rotate (enabled by default, should be set to one) to set the count to zero... ***/
	while ([UIDevice currentDevice].generatesDeviceOrientationNotifications) {
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	}
	
	/* ... to set the count to one (to disable it by calling "-[UIDevice endGeneratingDeviceOrientationNotifications]") */
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:) 
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
	
	return YES;
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
	/* Don't show the landscape mode if it's not allowed (Normally, this will not be called, it's just to prevent) */
	if (![UIDevice currentDevice].generatesDeviceOrientationNotifications)
		return ;
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	
	static UIDeviceOrientation oldLandscapeOrientation = UIDeviceOrientationUnknown;
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	// @TODO: Test with all device orientation (face up, face down, etc.)
	borderMaskWindow.hidden = (UIDeviceOrientationIsLandscape(orientation) /*&& !UIDeviceOrientationIsLandscape(oldLandscapeOrientation))*/ || orientation == UIDeviceOrientationPortraitUpsideDown);
	
	if (UIDeviceOrientationIsLandscape(orientation)) {
		if (landscapeWindow) {
			/*  If the "landscapeWindow" is showing and we are into the landscape mode,
			 that means we have change the orientation of the device (from landscape right/left to landscape left/right),
			 change the anchor and frame of the window to have a rotation on center effect */
			
			landscapeWindow.layer.anchorPoint = CGPointMake(0.5, 0.5);
			landscapeWindow.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
			
			CGAffineTransform transform = CGAffineTransformMakeRotation((orientation == UIDeviceOrientationLandscapeLeft)? M_PI_2 : -M_PI_2);
			[UIView animateWithDuration:0.5
							 animations:^{
								 landscapeWindow.transform = transform;
							 }];
			
			if (orientation == UIDeviceOrientationLandscapeLeft) {
				window.transform = CGAffineTransformMakeRotation(M_PI_2);
				window.layer.anchorPoint = CGPointZero;
				window.frame = CGRectMake(0., 0., screenSize.height, screenSize.width);
			} else {
				window.transform = CGAffineTransformMakeRotation(-M_PI_2);
				window.layer.anchorPoint = CGPointMake(1., 0.);
				
				CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + 320));
				window.frame = CGRectMake(x, 0., screenSize.height, screenSize.width);
			}
			
		} else {
			CGRect frame = CGRectMake(0., 0., screenSize.height, screenSize.width);
			landscapeWindow = [[UIWindow alloc] initWithFrame:frame];
			landscapeWindow.backgroundColor = [UIColor redColor];
			
			LandscapeViewController * landscapeViewController = [[LandscapeViewController alloc] init];
			landscapeViewController.view.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
			[landscapeWindow addSubview:landscapeViewController.view];
			
			[landscapeWindow makeKeyAndVisible];
			landscapeWindow.clipsToBounds = YES;
			
			CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
			if (orientation == UIDeviceOrientationLandscapeLeft) {
				landscapeWindow.layer.anchorPoint = CGPointMake(0., 1.);
				landscapeWindow.frame = CGRectMake(0., -screenSize.width, screenSize.height, screenSize.width);
				
				window.layer.anchorPoint = CGPointZero;
				window.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
				
			} else {
				landscapeWindow.layer.anchorPoint = CGPointMake(1., 1.);
				CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + 320));
				landscapeWindow.frame = CGRectMake(x, -screenSize.width, screenSize.height, screenSize.width);
				transform = CGAffineTransformMakeRotation(-M_PI_2);
				
				window.layer.anchorPoint = CGPointMake(1., 0.);
				window.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
			}
			
			[[UIApplication sharedApplication] setStatusBarHidden:YES];
			
			[UIView animateWithDuration:0.5
							 animations:^{
								 window.transform = transform;
								 landscapeWindow.transform = transform;
							 }];
		}
		
		oldLandscapeOrientation = orientation;
		
	} else if (orientation == UIDeviceOrientationPortrait) {
		if (landscapeWindow) {
			/* Make sure that we go back to the left/right top corner rotation effect if we have set the rotation on center effect. */
			if (oldLandscapeOrientation == UIDeviceOrientationLandscapeLeft) {
				landscapeWindow.layer.anchorPoint = CGPointMake(0., 1.);
				landscapeWindow.frame = CGRectMake(0., -screenSize.width, screenSize.height, screenSize.width);
				landscapeWindow.transform = CGAffineTransformMakeRotation(M_PI_2);
			} else if (oldLandscapeOrientation == UIDeviceOrientationLandscapeRight) {
				landscapeWindow.layer.anchorPoint = CGPointMake(1., 1.);
				CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + 320));
				landscapeWindow.frame = CGRectMake(x, -screenSize.width, screenSize.height, screenSize.width);
				landscapeWindow.transform = CGAffineTransformMakeRotation(-M_PI_2);
			}
			
			[UIView animateWithDuration:0.5
							 animations:^{
								 window.transform = CGAffineTransformIdentity;
								 landscapeWindow.layer.transform = CATransform3DIdentity;
							 }
							 completion:^(BOOL finished) {
								 [[UIApplication sharedApplication] setStatusBarHidden:NO
																		 withAnimation:UIStatusBarAnimationFade];
								 
								 landscapeWindow = nil;
							 }];
		}
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Update to handle the error appropriately.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
        } 
    }
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"verbs.sqlite"];
	/*
	 Set up the store.
	 For the sake of illustration, provide a pre-populated default store.
	 */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"verbs" ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	NSError *error;
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
	
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    
}


@end
