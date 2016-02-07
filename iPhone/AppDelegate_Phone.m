//
//  AppDelegate_Phone.m
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

#import "AppDelegate_Phone.h"

#import "LandscapeViewController.h"
#import "RootNavigationController.h"
#import "QuizViewController.h"
#import "Quote.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation AppDelegate_Phone

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[Fabric with:@[ Crashlytics.class ]];
	
    _window.tintColor = [UIColor purpleColor];
    
	PlaylistsViewController * playlistsViewController = [[PlaylistsViewController alloc] init];
	
	_navigationController = [[RootNavigationController alloc] initWithRootViewController:playlistsViewController];
	_window.rootViewController = _navigationController;
	
    [_window makeKeyAndVisible];
    
	/*** Hack: Disable the sending of notifications when the device rotate (enabled by default, should be set to one) to set the count to zero... ***/
	while ([UIDevice currentDevice].generatesDeviceOrientationNotifications) {
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	}
	
	/* ... to set the count to one (to disable it by calling "-[UIDevice endGeneratingDeviceOrientationNotifications]") */
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
	
	// On iOS 9+, index all verbs with Spotlight
	[[Playlist allVerbsPlaylist] buildingSpolightIndexWithCompletionHandler:^(NSError * _Nullable error) {
		if (error) {
			NSLog(@"error when building Spotlight index: %@", error.localizedDescription);
		} }];
	
	return YES;
}

- (void)showVerbWithInfinitif:(NSString *)infinitif
{
	Verb * verb = [[Playlist allVerbsPlaylist] verbWithInfinitif:infinitif];
	if (verb) {
		if (_navigationController.presentedViewController)
			[_navigationController dismissViewControllerAnimated:NO completion:nil];
		[_navigationController popToRootViewControllerAnimated:NO];
		
		SearchViewController * searchViewController = [[SearchViewController alloc] init];
		searchViewController.playlist = [Playlist allVerbsPlaylist];
		[_navigationController pushViewController:searchViewController animated:NO];
		
		ResultViewController * resultViewController = [[ResultViewController alloc] init];
		resultViewController.verb = verb;
		[_navigationController pushViewController:resultViewController animated:YES];
	}
}

- (void)showQuizForPlaylist:(Playlist *)playlist firstVerbWithInfinitif:(NSString *)infinitif tense:(NSString *)tense
{
	Verb * verb = [playlist verbWithInfinitif:infinitif];
	if (verb) {
		[_navigationController dismissViewControllerAnimated:NO completion:nil];
		
		VerbForm form = ([tense isEqualToString:@"past-participle"]) ? VerbFormPastParticiple : VerbFormPastSimple;
		QuizViewController * controller = [[QuizViewController alloc] initWithPlaylist:playlist firstVerb:verb verbForm:form];
		
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		[_navigationController presentViewController:navigationController animated:NO completion:nil];
	}
}

- (BOOL)openDeeplinkURL:(NSURL *)url
{
	if ([url.host isEqualToString:@"verb"]) { // iverb://verb#[infinitif]
		[self showVerbWithInfinitif:url.fragment];
		return YES;
		
	} else { // iverb://quiz/[playlist name]/[infinitif]#[past/past-participle]
		NSString * urlString = url.absoluteString.stringByRemovingPercentEncoding;
		NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"iverb://quiz\\/([^\\/]+)\\/([^#]+)#(.+)$"
																				options:NSRegularExpressionCaseInsensitive
																				  error:nil];
		if ([regex matchesInString:urlString options:0 range:NSMakeRange(0, urlString.length)]) {
			NSString * playlistName = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, urlString.length) withTemplate:@"$1"];
			NSString * infinitif = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, urlString.length) withTemplate:@"$2"];
			NSString * tense = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, urlString.length) withTemplate:@"$3"];
			[self showQuizForPlaylist:[Playlist playlistWithName:playlistName] firstVerbWithInfinitif:infinitif tense:tense];
			return YES;
		}
	}
	return NO;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * _Nullable))restorationHandler
{
	if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
		NSString * infinitif = userActivity.userInfo[CSSearchableItemActivityIdentifier];
		[self showVerbWithInfinitif:infinitif];
	}
	return YES;
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
	// Don't show the landscape mode if it's not allowed (Normally, this will not be called, it's just to prevent)
	if (![UIDevice currentDevice].generatesDeviceOrientationNotifications)
		return ;
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	
	static UIDeviceOrientation oldLandscapeOrientation = UIDeviceOrientationUnknown;
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if (UIDeviceOrientationIsLandscape(orientation)) {
		if (landscapeWindow) {
			// If the "landscapeWindow" is showing and we are into the landscape mode,
			//   that means we have change the orientation of the device (from landscape right/left to landscape left/right),
			//   change the anchor and frame of the window to have a rotation on center effect
			
			landscapeWindow.layer.anchorPoint = CGPointMake(0.5, 0.5);
			landscapeWindow.frame = CGRectMake(0., 0., screenSize.height, screenSize.width);
			
			CGAffineTransform transform = CGAffineTransformMakeRotation((orientation == UIDeviceOrientationLandscapeLeft)? M_PI_2 : -M_PI_2);
			[UIView animateWithDuration:0.5
							 animations:^{ landscapeWindow.transform = transform; }];
			
			if (orientation == UIDeviceOrientationLandscapeLeft) {
				_window.transform = CGAffineTransformMakeRotation(M_PI_2);
				_window.layer.anchorPoint = CGPointZero;
				_window.frame = CGRectMake(0., 0., screenSize.height, screenSize.width);
			} else {
				_window.transform = CGAffineTransformMakeRotation(-M_PI_2);
				_window.layer.anchorPoint = CGPointMake(1., 0.);
				
				CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + 320));
				_window.frame = CGRectMake(x, 0., screenSize.height, screenSize.width);
			}
			
		} else {
			CGRect frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
			landscapeWindow = [[UIWindow alloc] initWithFrame:frame];
			landscapeWindow.backgroundColor = [UIColor redColor];
			
			LandscapeViewController * landscapeViewController = [[LandscapeViewController alloc] init];
			landscapeViewController.view.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
			[landscapeWindow addSubview:landscapeViewController.view];
			
            landscapeWindow.windowLevel = UIWindowLevelAlert;
			[landscapeWindow makeKeyAndVisible];
			landscapeWindow.clipsToBounds = YES;
			
			CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
			if (orientation == UIDeviceOrientationLandscapeLeft) {
				landscapeWindow.layer.anchorPoint = CGPointMake(0., 1.);
				landscapeWindow.frame = CGRectMake(0., -screenSize.width, screenSize.height, screenSize.width);
				
				_window.layer.anchorPoint = CGPointZero;
				_window.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
				
			} else {
				landscapeWindow.layer.anchorPoint = CGPointMake(1., 1.);
				CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + 320));
				landscapeWindow.frame = CGRectMake(x, -screenSize.width, screenSize.height, screenSize.width);
				transform = CGAffineTransformMakeRotation(-M_PI_2);
				
				_window.layer.anchorPoint = CGPointMake(1., 0.);
				_window.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
			}
			
            [UIApplication sharedApplication].statusBarHidden = YES;
			
			[UIView animateWithDuration:0.5
							 animations:^{
								 _window.transform = transform;
								 landscapeWindow.transform = transform;
							 }];
		}
		
		oldLandscapeOrientation = orientation;
		
	} else if (orientation == UIDeviceOrientationPortrait) {
		if (landscapeWindow) {
			// Make sure that we go back to the left/right top corner rotation effect if we have set the rotation on center effect.
			if (oldLandscapeOrientation == UIDeviceOrientationLandscapeLeft) {
				landscapeWindow.layer.anchorPoint = CGPointMake(0., 1.);
				landscapeWindow.frame = CGRectMake(0., -screenSize.width, screenSize.height, screenSize.width);
				landscapeWindow.transform = CGAffineTransformMakeRotation(M_PI_2);
			} else if (oldLandscapeOrientation == UIDeviceOrientationLandscapeRight) {
				landscapeWindow.layer.anchorPoint = CGPointMake(1., 1.);
				CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + 320)); // @FIXME: 320px? The hard-coded width of the iPhone???
				landscapeWindow.frame = CGRectMake(x, -screenSize.width, screenSize.height, screenSize.width);
				landscapeWindow.transform = CGAffineTransformMakeRotation(-M_PI_2);
			}
			
			[UIView animateWithDuration:0.5
							 animations:^{
								 _window.transform = CGAffineTransformIdentity;
								 landscapeWindow.layer.transform = CATransform3DIdentity; }
							 completion:^(BOOL finished) { landscapeWindow = nil; }];
		}
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error;
    if (managedObjectContext != nil) {
        if (managedObjectContext.hasChanges && ![managedObjectContext save:&error]) {
			NSLog(@"Unresolved error %@, %@", error, error.userInfo);
			exit(-1); // Fail
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.persistentStoreCoordinator = coordinator;
		
		NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Verb"];
		request.predicate = [NSPredicate predicateWithFormat:@"SELF.quote == nil"];
		NSArray * verbs = [managedObjectContext executeFetchRequest:request error:NULL];
		if (verbs.count > 0) {
			
			NSPersistentStoreCoordinator * applicationStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
			NSURL * applicationStoreURL = [[NSBundle mainBundle] URLForResource:@"verbs" withExtension:@"sqlite"];
			if ([applicationStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:applicationStoreURL options:@{} error:NULL]) {
				NSManagedObjectContext * appContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
				appContext.persistentStoreCoordinator = applicationStoreCoordinator;
				
				__block NSMutableDictionary <NSString *, NSDictionary <NSString *, NSString *> *> * infinitivesAndQuotes = [[NSMutableDictionary alloc] initWithCapacity:verbs.count];
				NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Quote"];
				[[appContext executeFetchRequest:request error:NULL] enumerateObjectsUsingBlock:^(Quote * _Nonnull quote, NSUInteger idx, BOOL * _Nonnull stop) {
					NSString * infinitif = quote.verb.infinitif;
					NSMutableDictionary <NSString *, NSString *> * quoteDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
					if (quote.infinitif) {
						quoteDictionary[@"i"] = quote.infinitif; }
					if (quote.past) {
						quoteDictionary[@"p"] = quote.past; }
					if (quote.pastParticiple) {
						quoteDictionary[@"pp"] = quote.pastParticiple; }
					infinitivesAndQuotes[infinitif] = quoteDictionary;
				}];
				for (Verb * verb in verbs) {
					if (infinitivesAndQuotes[verb.infinitif].allKeys.count > 0) {
						NSEntityDescription * entity = [NSEntityDescription entityForName:@"Quote" inManagedObjectContext:verb.managedObjectContext];
						Quote * quote = (Quote *)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:verb.managedObjectContext];
						quote.infinitif = infinitivesAndQuotes[verb.infinitif][@"i"];
						quote.past = infinitivesAndQuotes[verb.infinitif][@"p"];
						quote.pastParticiple = infinitivesAndQuotes[verb.infinitif][@"pp"];
						[verb setValue:quote forKey:@"quote"];
					}
				}
				[managedObjectContext save:NULL];
			}
		}
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
	if (![[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"verbs" ofType:@"sqlite"];
		if (defaultStorePath) {
			[[NSFileManager defaultManager] copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES };
	NSError *error;
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, error.userInfo);
		exit(-1);  // Fail
	}
	
	return persistentStoreCoordinator;
}

#pragma mark - Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

#pragma mark - Memory management

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
