//
//  UserData.h
//  iVerb
//
//  Created by Max on 16/04/2017.
//
//

@import Foundation;
@import CoreData;

/// This class manages synchronisation of user data (playlists, bookmarks, history, notes, etc.) with user defaults, Core Data and iCloud
@interface UserDataManager : NSObject

+ (instancetype)defaultManager;

- (BOOL)synchronize;

@end
