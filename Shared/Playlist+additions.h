//
//  Playlist+additions.h
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Playlist.h"

@interface Playlist (additions)

+ (Playlist *)currentPlaylist;
+ (void)setCurrentPlaylist:(Playlist *)playlist;

- (NSString *)localizedName;

- (NSString *)HTMLFormat;

/**
 Index all verbs from the current playlist in Spotlight. Does nothing in iOS 8 and earlier (the completion handler is not even called).
 */
- (void)buildingSpolightIndexWithCompletionHandler:(void (^ __nullable)(NSError * __nullable error))completionHandler NS_AVAILABLE(NA, 9_0);

@end
