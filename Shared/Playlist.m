//
//  Playlist.m
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist.h"
#import "ManagedObjectContext.h"

// Notification names
NSString * const PlaylistDidCreateNotification = @"PlaylistDidCreateNotification";
NSString * const PlaylistDidUpdateNameNotification = @"PlaylistDidUpdateNameNotification";
NSString * const PlaylistWillDeleteNotification = @"PlaylistWillDeleteNotification";

NSString * const PlaylistDidAddVerbNotification = @"PlaylistDidAddVerbNotification";
NSString * const PlaylistDidRemoveVerbNotification = @"PlaylistDidRemoveVerbNotification";

// Default playlist names
NSString * const kPlaylistCommonsName = @"_COMMONS_";
NSString * const kPlaylistHistoryName = @"_HISTORY_";
NSString * const kPlaylistBookmarksName = @"_BOOKMARKS_";
NSString * const kPlaylistAllVerbsName = @"_ALL_VERBS_";

@implementation Playlist

@dynamic name;
@dynamic creationDate;
@dynamic verbs;
@dynamic quizResults;

@dynamic isDefaultPlaylist;

+ (Playlist *)allVerbsPlaylist
{
	static Playlist * __allVerbsPlaylist = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__allVerbsPlaylist = [self playlistWithName:kPlaylistAllVerbsName];
	});
	return __allVerbsPlaylist;
}

+ (Playlist *)commonsVerbsPlaylist
{
	static Playlist * __basicVerbsPlaylist = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__basicVerbsPlaylist = [self playlistWithName:kPlaylistCommonsName];
	});
	return __basicVerbsPlaylist;
}

+ (Playlist *)bookmarksPlaylist
{
	static Playlist * __bookmarksPlaylist = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__bookmarksPlaylist = [self playlistWithName:kPlaylistBookmarksName];
	});
	return __bookmarksPlaylist;
}

+ (Playlist *)historyPlaylist
{
	static Playlist * __historyPlaylist = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__historyPlaylist = [self playlistWithName:kPlaylistHistoryName];
	});
	return __historyPlaylist;
}

+ (NSArray *)defaultPlaylists
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"%K == NULL", SelectorName(creationDate)];
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL];
}

+ (NSArray *)userPlaylists
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"%K != NULL", SelectorName(creationDate)];
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL];
}

+ (Playlist *)playlistWithName:(NSString *)name
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", SelectorName(name), name];
	request.fetchLimit = 1;
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:SelectorName(creationDate) ascending:NO];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL].firstObject;
}

- (BOOL)canBeModified
{
	return (![self.name isEqualToString:kPlaylistAllVerbsName] && ![self.name isEqualToString:kPlaylistCommonsName]);
}

- (BOOL)isCommonsPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:kPlaylistCommonsName]);
}

- (BOOL)isAllVerbsPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:kPlaylistAllVerbsName]);
}

- (BOOL)isHistoryPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:kPlaylistHistoryName]);
}

- (BOOL)isBookmarksPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:kPlaylistBookmarksName]);
}

- (BOOL)isDefaultPlaylist
{
	return (self.creationDate == nil);
}

- (BOOL)isUserPlaylist
{
	return !(self.isDefaultPlaylist);
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistDidCreateNotification object:self.name];
}

- (void)prepareForDeletion
{
	[super prepareForDeletion];
	[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistWillDeleteNotification object:self.name];
}

- (void)setName:(NSString *)name
{
	NSString * const oldName = self.name;
	NSString * const key = SelectorName(name);
	[self willChangeValueForKey:key];
	[self setPrimitiveValue:name forKey:key];
	[self didChangeValueForKey:key];
	
	if (oldName)
		[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistDidUpdateNameNotification
															object:self userInfo:@{ @"oldName" : oldName }];
}

- (void)addVerb:(Verb *)verb
{
	[[self mutableSetValueForKey:@"verbs"] addObject:verb];
	[self.managedObjectContext save:NULL];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistDidAddVerbNotification
														object:self userInfo:@{ @"verb" : verb }];
}

- (void)removeVerb:(Verb *)verb
{
	[[self mutableSetValueForKey:@"verbs"] removeObject:verb];
	[self.managedObjectContext save:NULL];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PlaylistDidRemoveVerbNotification
														object:self userInfo:@{ @"verb" : verb }];
}

@end
