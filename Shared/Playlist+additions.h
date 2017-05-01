//
//  Playlist+additions.h
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreSpotlight;
@import MobileCoreServices;
@import WatchConnectivity;

#import "Playlist.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PlaylistAction) {
	/// When selecting a playlist (saved in user defaults)
	PlaylistActionSelect,
	
	/// When added/remove a verb to a playlist (not saved in user defaults)
	PlaylistActionAddTo
};

typedef NS_ENUM(NSUInteger, SharedDestination) {
	/// Update shared user default for widget
	SharedDestinationWidget,
	
	/// Update shared user default for Apple Watch; a valid WCSession must has been activated.
	SharedDestinationWatch
};

@interface Playlist (additions)

+ (nullable Playlist *)playlistForAction:(PlaylistAction)action;
+ (void)setPlaylist:(nullable Playlist *)playlist forAction:(PlaylistAction)action;

+ (Playlist *)insertPlaylistWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSString *)localizedName;

- (NSString *)HTMLFormat;

- (nullable Verb *)verbWithInfinitif:(nullable NSString *)infinitif;

@end

@interface Playlist (Spotlight)

/// Index all verbs from the current playlist in Spotlight. Does nothing in iOS 8 and earlier (the completion handler is not even called).
- (void)buildingSpolightIndexWithCompletionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler NS_AVAILABLE(NA, 9_0);

@end

@interface Playlist (SharedPlaylist)

- (void)updateSharedVerbsFor:(SharedDestination)destination;

@end

NS_ASSUME_NONNULL_END
