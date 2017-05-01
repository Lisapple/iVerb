//
//  AppDelegate_Pad.m
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

#import "AppDelegate_Pad.h"
#import "QuizViewController.h"
#import "MainViewController.h"

#import "ManagedObjectContext.h"
#import "UserDataManager.h"

@implementation AppDelegate_Pad

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !TARGET_IPHONE_SIMULATOR
	[Fabric with:@[ CrashlyticsKit ]];
#endif
	
	NSDictionary * attributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:20.],
								   NSForegroundColorAttributeName : [UIColor darkGrayColor] };
	[UINavigationBar appearance].titleTextAttributes = attributes;
	
    self.window.tintColor = [UIColor purpleColor];
	
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
	if (verb)
		[[NSNotificationCenter defaultCenter] postNotificationName:SearchTableViewDidSelectCellNotification object:verb];
}

- (void)showQuizForPlaylist:(nonnull Playlist *)playlist firstVerbWithInfinitif:(nullable NSString *)infinitif tense:(nullable NSString *)tense
{
	Verb * verb = [playlist verbWithInfinitif:infinitif];
	if (verb) {
		[_window.rootViewController dismissViewControllerAnimated:NO completion:nil];
		
		VerbForm form = VerbFormUnspecified;
		if /**/ ([tense isEqualToString:@"past"])
			form = VerbFormPastSimple;
		else if ([tense isEqualToString:@"past-participle"])
			form = VerbFormPastParticiple;
		
		QuizViewController * controller = [[QuizViewController alloc] initWithPlaylist:playlist firstVerb:verb verbForm:form];
		
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[_window.rootViewController presentViewController:navigationController animated:NO completion:nil];
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

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options // iOS 9+
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation // iOS 8
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler
{
	if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
		NSString * infinitif = userActivity.userInfo[CSSearchableItemActivityIdentifier];
		[self showVerbWithInfinitif:infinitif];
	}
	return NO;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	return UIInterfaceOrientationMaskAll;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[UserDataManager defaultManager] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error;
    if (managedObjectContext != nil) {
        if (managedObjectContext.hasChanges && ![managedObjectContext save:&error]) {
			// @TODO: Do something with the error
        }
    }
	[[UserDataManager defaultManager] synchronize];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.persistentStoreCoordinator = coordinator;
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}

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

- (NSString *)applicationDocumentsDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

@end
