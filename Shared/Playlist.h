//
//  Playlist.h
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreData;

@class Verb;
@class QuizResult;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kPlaylistCommonsName;
extern NSString * const kPlaylistHistoryName;
extern NSString * const kPlaylistBookmarksName;
extern NSString * const kPlaylistAllVerbsName;

@interface Playlist : NSManagedObject // @TODO: Rename to "Verblist"

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSDate * creationDate;

@property (nonatomic, strong) NSSet <Verb *> * verbs;
@property (nonatomic, strong) NSSet <QuizResult *> * quizResults;

@property (nonatomic, readonly) BOOL isDefaultPlaylist;

+ (Playlist *)allVerbsPlaylist;
+ (Playlist *)commonsVerbsPlaylist;
+ (Playlist *)bookmarksPlaylist;
+ (Playlist *)historyPlaylist;

+ (NSArray <Playlist *> *)defaultPlaylists;
+ (NSArray <Playlist *> *)userPlaylists;

+ (nullable Playlist *)playlistWithName:(NSString *)name;

- (BOOL)canBeModified;
- (BOOL)isCommonsPlaylist;
- (BOOL)isAllVerbsPlaylist;
- (BOOL)isHistoryPlaylist;
- (BOOL)isBookmarksPlaylist;
- (BOOL)isDefaultPlaylist;
- (BOOL)isUserPlaylist;

- (nullable Verb *)verbWithInfinitif:(nullable NSString *)infinitif;
- (void)addVerb:(Verb *)verb;
- (void)removeVerb:(Verb *)verb;

@end

NS_ASSUME_NONNULL_END
