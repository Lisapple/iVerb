//
//  AppDelegate_Phone.h
//  iVerb
//
//  Created by Max on 9/11/10.
//  Copyright Lisacintosh 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreSpotlight/CoreSpotlight.h>

#import "ManagedObjectContext.h"
#import "Playlist+additions.h"

@interface AppDelegate_Phone : UIResponder <UIApplicationDelegate, UITabBarDelegate, ManagedObjectContext>
 
@property (nonatomic, strong) UIWindow * landscapeWindow;

@property (nonatomic, strong) NSManagedObjectModel * managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator * persistentStoreCoordinator;

@property (nonatomic, strong, readonly) NSString * applicationDocumentsDirectory;

@property (nonatomic, strong) IBOutlet UIWindow * window;
@property (nonatomic, strong) UINavigationController * navigationController;

@property (nonatomic, strong) NSDictionary * dictionary;

@end

