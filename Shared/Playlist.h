//
//  Playlist.h
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Verb.h"

@class Verb;

@interface Playlist : NSManagedObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSDate * creationDate;

@property (nonatomic, strong) NSSet * verbs;

@property (nonatomic, readonly) BOOL isDefaultPlaylist;

+ (Playlist *)lastUsedPlaylist;

+ (Playlist *)allVerbsPlaylist;
+ (Playlist *)basicVerbsPlaylist;
+ (Playlist *)bookmarksPlaylist;
+ (Playlist *)historyPlaylist;

+ (NSArray *)defaultPlaylists;
+ (NSArray *)userPlaylists;

+ (Playlist *)playlistWithName:(NSString *)name;

- (BOOL)canBeModified;
- (BOOL)isHistoryPlaylist;
- (BOOL)isDefaultPlaylist;
- (BOOL)isUserPlaylist;

- (void)addVerb:(Verb *)verb;
- (void)removeVerb:(Verb *)verb;

@end
