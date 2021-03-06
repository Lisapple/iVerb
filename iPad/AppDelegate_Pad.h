//
//  AppDelegate_Pad.h
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

@import CoreData;
@import CoreSpotlight;
@import Fabric;
@import Crashlytics;

#import "ManagedObjectContext.h"

@interface AppDelegate_Pad : UIResponder <UIApplicationDelegate, ManagedObjectContext>
{
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) IBOutlet UIWindow *window;

// Private
- (NSString *)applicationDocumentsDirectory;

@end

