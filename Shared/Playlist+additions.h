//
//  Playlist+additions.h
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreSpotlight;
@import MobileCoreServices;

#import "Playlist.h"

typedef NS_ENUM(NSUInteger, PlaylistAction) {
	/** When selecting a playlist (saved in user defaults) */
	PlaylistActionSelect,
	
	/** When added/remove a verb to a playlist (not saved in user defaults) */
	PlaylistActionAddTo
};

@interface Playlist (additions)

+ (nullable Playlist *)playlistForAction:(PlaylistAction)action;
+ (void)setPlaylist:(nullable Playlist *)playlist forAction:(PlaylistAction)action;

- (nonnull NSString *)localizedName;
+ (Playlist *)insertPlaylistWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;


- (nullable Verb *)verbWithInfinitif:(nullable NSString *)infinitif;

- (nonnull NSString *)HTMLFormat;

/**
 Index all verbs from the current playlist in Spotlight. Does nothing in iOS 8 and earlier (the completion handler is not even called).
 */
- (void)buildingSpolightIndexWithCompletionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler NS_AVAILABLE(NA, 9_0);

@end
