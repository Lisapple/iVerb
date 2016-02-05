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

#import "PlaylistsViewController.h"
#import "SearchViewController.h"
#import "ResultViewController.h"

#import "ManagedObjectContext.h"
#import "Playlist+additions.h"

@interface AppDelegate_Phone : NSObject <UIApplicationDelegate, UITabBarDelegate, ManagedObjectContext>
{
	NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	
    UIWindow * landscapeWindow;
	
	@private
	UINavigationController * _navigationController;
}

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (unsafe_unretained, nonatomic, readonly) NSString *applicationDocumentsDirectory;

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong) NSDictionary * dictionary;

@end

