//
//  Playlist.h
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Notification names

extern NSString * const PlaylistDidCreateNotification; // object = playlist
extern NSString * const PlaylistDidUpdateNameNotification; // object = playlist, userInfo = { "oldName" = NSString }
extern NSString * const PlaylistWillDeleteNotification; // object = playlist
	
extern NSString * const PlaylistDidAddVerbNotification; // object = playlist, userInfo = { "verb" = Verb }
extern NSString * const PlaylistDidRemoveVerbNotification; // object = playlist, userInfo = { "verb" = Verb }

#pragma mark - Default playlist names

extern NSString * const kPlaylistCommonsName;
extern NSString * const kPlaylistHistoryName;
extern NSString * const kPlaylistBookmarksName;
extern NSString * const kPlaylistAllVerbsName;

@class Verb;
@class QuizResult;
@interface Playlist : NSManagedObject // @TODO: Rename to "Verblist"

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSDate * creationDate; // @TODO: Should be readonly

@property (nonatomic, strong) NSSet <Verb *> * verbs;
@property (nonatomic, strong) NSSet <QuizResult *> * quizResults;

@property (nonatomic, readonly) BOOL isDefaultPlaylist;

+ (Playlist *)allVerbsPlaylist;
+ (Playlist *)commonsVerbsPlaylist;
+ (Playlist *)bookmarksPlaylist;
+ (Playlist *)historyPlaylist;

+ (NSArray <Playlist *> *)defaultPlaylists;
+ (NSArray <Playlist *> *)userPlaylists;

+ (nullable Playlist *)playlistWithObjectID:(NSManagedObjectID *)objectID;
+ (nullable Playlist *)playlistWithName:(NSString *)name;

- (BOOL)canBeModified;
- (BOOL)isCommonsPlaylist;
- (BOOL)isAllVerbsPlaylist;
- (BOOL)isHistoryPlaylist;
- (BOOL)isBookmarksPlaylist;
- (BOOL)isDefaultPlaylist;
- (BOOL)isUserPlaylist;

- (void)addVerb:(Verb *)verb;
- (void)removeVerb:(Verb *)verb;

@end

NS_ASSUME_NONNULL_END
