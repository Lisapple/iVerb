//
//  Playlist+additions.h
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist.h"

@interface Playlist (additions)

+ (Playlist *)currentPlaylist;
+ (void)setCurrentPlaylist:(Playlist *)playlist;

- (NSString *)localizedName;

- (NSString *)HTMLFormat;

@end
