//
//  AppDelegate_Phone.m
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

#import "AppDelegate_Phone.h"

#import "LandscapeViewController.h"
#import "QuizViewController.h"
#import "Quote.h"

#import "PlaylistsViewController.h"
#import "SearchViewController.h"
#import "ResultViewController.h"

@implementation AppDelegate_Phone

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_IPHONE_SIMULATOR
#else
	[Fabric with:@[ CrashlyticsKit ]];
#endif
	
	NSDictionary * attributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:20.],
								   NSForegroundColorAttributeName : [UIColor darkGrayColor] };
	[UINavigationBar appearance].titleTextAttributes = attributes;
	
	_window.backgroundColor = [UIColor blackColor];
	_window.tintColor = [UIColor purpleColor];
	_navigationController = (UINavigationController *)_window.rootViewController;
	
	SearchViewController * searchViewController = [[SearchViewController alloc] init];
	searchViewController.playlist = [Playlist playlistForAction:PlaylistActionSelect];
	[_navigationController pushViewController:searchViewController animated:NO];
	
	[self enableDeviceRotation];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
	
	// On iOS 9+, index all verbs with Spotlight
	[[Playlist allVerbsPlaylist] buildingSpolightIndexWithCompletionHandler:^(NSError * _Nullable error) {
		if (error) {
			NSLog(@"error when building Spotlight index: %@", error.localizedDescription);
		} }];
	
	return YES;
}

- (void)disableDeviceRotation
{
	/*** Hack: Disable the sending of notifications when the device rotate (enabled by default, should be set to one) to set the count to zero... ***/
	while ([UIDevice currentDevice].generatesDeviceOrientationNotifications)
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)enableDeviceRotation
{
	[self disableDeviceRotation];
	/* ... to set the count to one (to disable it by calling "-[UIDevice endGeneratingDeviceOrientationNotifications]") */
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
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

- (void)showQuizForPlaylist:(nonnull Playlist *)playlist firstVerbWithInfinitif:(nullable NSString *)infinitif tense:(nullable NSString *)tense
{
	[_navigationController dismissViewControllerAnimated:NO completion:nil];
	
	Verb * verb = [playlist verbWithInfinitif:infinitif];
	
	VerbForm form = VerbFormUnspecified;
	if /**/ ([tense isEqualToString:@"past"])
		form = VerbFormPastSimple;
	else if ([tense isEqualToString:@"past-participle"])
		form = VerbFormPastParticiple;
	
	QuizViewController * controller = [[QuizViewController alloc] initWithPlaylist:playlist firstVerb:verb verbForm:form];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	[_navigationController presentViewController:navigationController animated:NO completion:nil];
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
			NSString * playlistName = [regex stringByReplacingMatchesInString:urlString options:0
																		range:NSMakeRange(0, urlString.length) withTemplate:@"$1"];
			Playlist * playlist = [Playlist playlistWithName:playlistName];
			if (playlist) {
				NSString * infinitif = [regex stringByReplacingMatchesInString:urlString options:0
																		 range:NSMakeRange(0, urlString.length) withTemplate:@"$2"];
				NSString * tense = [regex stringByReplacingMatchesInString:urlString options:0
																	 range:NSMakeRange(0, urlString.length) withTemplate:@"$3"];
				[self showQuizForPlaylist:playlist firstVerbWithInfinitif:infinitif tense:tense];
				return YES;
			}
			return NO;
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

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
	if /**/ ([shortcutItem.type isEqualToString:@"com.lisacintosh.iverb.show.search"]) { // Search
		// Open search field from all verbs playlist
		[_navigationController popToRootViewControllerAnimated:NO];
		SearchViewController * searchViewController = [[SearchViewController alloc] init];
		searchViewController.playlist = [Playlist allVerbsPlaylist];
		[_navigationController pushViewController:searchViewController animated:NO];
		dispatch_async(dispatch_get_main_queue(), ^{
			[searchViewController focusSearch]; completionHandler(YES); });
	}
	else if ([shortcutItem.type isEqualToString:@"com.lisacintosh.iverb.show.bookmarks"]) { // Favorites
		// Open Bookmarks playlist
		[_navigationController popToRootViewControllerAnimated:NO];
		SearchViewController * searchViewController = [[SearchViewController alloc] init];
		searchViewController.playlist = [Playlist historyPlaylist];
		[_navigationController pushViewController:searchViewController animated:NO];
		completionHandler(YES);
	}
	else if ([shortcutItem.type isEqualToString:@"com.lisacintosh.iverb.launch.quiz"]) { // Quizz (last selected playlist)
		NSString * playlistName = (NSString *)shortcutItem.userInfo[@"playlist"];
		[self showQuizForPlaylist:[Playlist playlistWithName:playlistName] firstVerbWithInfinitif:nil tense:nil];
		completionHandler(YES);
	}
	else {
		completionHandler(NO);
	}
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
	
	if (orientation == oldLandscapeOrientation)
		return ;
	
	if (UIDeviceOrientationIsLandscape(orientation)) { // Rotating to landscape
		if (UIDeviceOrientationIsPortrait(oldLandscapeOrientation)) {
			if (_landscapeWindow) {
				// If the "_landscapeWindow" is showing and we are into the landscape mode,
				//   that means we have change the orientation of the device (from landscape right/left to landscape left/right),
				//   change the anchor and frame of the window to have a rotation on center effect
				
				_landscapeWindow.layer.anchorPoint = CGPointMake(0.5, 0.5);
				_landscapeWindow.frame = CGRectMake(0., 0., screenSize.height, screenSize.width);
				
				CGAffineTransform transform = CGAffineTransformMakeRotation((orientation == UIDeviceOrientationLandscapeLeft)? M_PI_2 : -M_PI_2);
				[UIView animateWithDuration:0.5
								 animations:^{ _landscapeWindow.transform = transform; }];
				
				if (orientation == UIDeviceOrientationLandscapeLeft) {
					_window.transform = CGAffineTransformMakeRotation(M_PI_2);
					_window.layer.anchorPoint = CGPointZero;
				} else {
					_window.transform = CGAffineTransformMakeRotation(-M_PI_2);
					_window.layer.anchorPoint = CGPointMake(1., 0.);
				}
				_window.frame = CGRectMake(0., 0., screenSize.height, screenSize.width);
				
			} else {
				CGRect frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
				_landscapeWindow = [[UIWindow alloc] initWithFrame:frame];
				_landscapeWindow.backgroundColor = [UIColor redColor];
				
				LandscapeViewController * landscapeViewController = [[LandscapeViewController alloc] init];
				landscapeViewController.view.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
				[_landscapeWindow addSubview:landscapeViewController.view];
				
				_landscapeWindow.windowLevel = UIWindowLevelAlert;
				[_landscapeWindow makeKeyAndVisible];
				_landscapeWindow.clipsToBounds = YES;
				
				CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
				if (orientation == UIDeviceOrientationLandscapeLeft) {
					_landscapeWindow.layer.anchorPoint = CGPointMake(0., 1.);
					_landscapeWindow.frame = CGRectMake(0., -screenSize.width, screenSize.height, screenSize.width);
					_window.layer.anchorPoint = CGPointZero;
				} else {
					_landscapeWindow.layer.anchorPoint = CGPointMake(1., 1.);
					CGFloat x = (-screenSize.height / 2. + (-screenSize.height / 2. + screenSize.width));
					_landscapeWindow.frame = CGRectMake(x, -screenSize.width, screenSize.height, screenSize.width);
					transform = CGAffineTransformMakeRotation(-M_PI_2);
					_window.layer.anchorPoint = CGPointMake(1., 0.);
				}
				_window.frame = CGRectMake(0., 0., screenSize.width, screenSize.height);
				
				[UIApplication sharedApplication].statusBarHidden = YES;
				
				[UIView animateWithDuration:0.5 delay:0
					 usingSpringWithDamping:0.85 initialSpringVelocity:0
									options:0
								 animations:^{
									 _window.transform = transform;
									 _landscapeWindow.transform = transform;
									 [self disableDeviceRotation];
								 }
								 completion:^(BOOL finished) {
									 dispatch_after_main(1, ^{ [self enableDeviceRotation]; });
								 }];
			}
		}
		oldLandscapeOrientation = orientation;
	} else if (orientation == UIDeviceOrientationPortrait) { // Rotating to portrait
		if (_landscapeWindow) {
			// Make sure that we go back to the left/right top corner rotation effect if we have set the rotation on center effect.
			if (oldLandscapeOrientation == UIDeviceOrientationLandscapeLeft) {
				_landscapeWindow.layer.anchorPoint = CGPointMake(0., 1.);
				_landscapeWindow.frame = CGRectMake(0., -screenSize.height, screenSize.width, screenSize.height);
				_landscapeWindow.transform = CGAffineTransformMakeRotation(M_PI_2);
			} else if (oldLandscapeOrientation == UIDeviceOrientationLandscapeRight) {
				_landscapeWindow.layer.anchorPoint = CGPointMake(1., 1.);
				CGFloat x = (-screenSize.width / 2. + (-screenSize.width / 2. + screenSize.width));
				_landscapeWindow.frame = CGRectMake(x, -screenSize.height, screenSize.width, screenSize.height);
				_landscapeWindow.transform = CGAffineTransformMakeRotation(-M_PI_2);
			}
			[UIView animateWithDuration:0.5
							 animations:^{
								 _window.transform = CGAffineTransformIdentity;
								 _landscapeWindow.layer.transform = CATransform3DIdentity;
								 [self disableDeviceRotation];
							 }
							 completion:^(BOOL finished) {
								 _landscapeWindow = nil;
								 dispatch_after_main(1, ^{ [self enableDeviceRotation]; });
							 }];
		}
		oldLandscapeOrientation = orientation;
	}
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSError *error;
    if (_managedObjectContext != nil) {
        if (_managedObjectContext.hasChanges && ![_managedObjectContext save:&error]) {
			// @TODO: Do something with the error
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.persistentStoreCoordinator = coordinator;
		
		NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Verb"];
		request.predicate = [NSPredicate predicateWithFormat:@"SELF.quote == nil"];
		NSArray * verbs = [_managedObjectContext executeFetchRequest:request error:NULL];
		if (verbs.count > 0) { // Add quotes from default database if user db doesn't contains all // @FIXME: Not all verbs contain quote, this executed at every launch
			
			NSPersistentStoreCoordinator * applicationStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
			NSURL * applicationStoreURL = [[NSBundle mainBundle] URLForResource:@"verbs" withExtension:@"sqlite"];
			
			NSDictionary * options = @{ NSReadOnlyPersistentStoreOption : @YES };
			if ([applicationStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
																	URL:applicationStoreURL options:options error:NULL]) {
				NSManagedObjectContext * appContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
				appContext.persistentStoreCoordinator = applicationStoreCoordinator;

				__block NSMutableDictionary <NSString *, Dictionary(String, String)> * infinitivesAndQuotes = [[NSMutableDictionary alloc] initWithCapacity:verbs.count];
				NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Quote"];
				[[appContext executeFetchRequest:request error:NULL] enumerateObjectsUsingBlock:^(Quote * quote, NSUInteger idx, BOOL * stop) {
					NSString * infinitif = quote.verb.infinitif;
					MDictionary(String, String) quoteDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
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
				[_managedObjectContext save:NULL];
			}
		}
    }
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
        return _managedObjectModel;
	
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (_persistentStoreCoordinator != nil)
		return _persistentStoreCoordinator;
	
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"verbs.sqlite"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"verbs" ofType:@"sqlite"];
		if (defaultStorePath) {
			[[NSFileManager defaultManager] copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES };
	NSError *error;
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, error.userInfo);
		exit(-1);  // Fail
	}
	
	return _persistentStoreCoordinator;
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
