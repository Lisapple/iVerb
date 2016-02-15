//
//  Playlist.m
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist.h"
#import "ManagedObjectContext.h"

NSString * const kPlaylistAllVerbsName = @"_ALL_VERBS_";
NSString * const kPlaylistBasicsVerbsName = @"_BASICS_VERBS_";
NSString * const kPlaylistBookmarksName = @"_BOOKMARKS_";
NSString * const kPlaylistHistoryName = @"_HISTORY_";

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

+ (Playlist *)basicVerbsPlaylist
{
	static Playlist * __basicVerbsPlaylist = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__basicVerbsPlaylist = [self playlistWithName:kPlaylistBasicsVerbsName];
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

+ (NSArray *)defaultPlaylist
{
	return [Playlist defaultPlaylists];
}

+ (NSArray *)defaultPlaylists
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"creationDate == NULL"];
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL];
}

+ (NSArray *)userPlaylists
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"creationDate != NULL"];
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL];
}

+ (Playlist *)playlistWithName:(NSString *)name
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	request.fetchLimit = 1;
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL].firstObject;
}

- (BOOL)canBeModified
{
	return (![self.name isEqualToString:kPlaylistAllVerbsName] && ![self.name isEqualToString:kPlaylistBasicsVerbsName]);
}

- (BOOL)isBasicPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:kPlaylistBasicsVerbsName]);
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
	return !self.isDefaultPlaylist;
}

- (Verb *)verbWithInfinitif:(NSString *)infinitif
{
	if (!infinitif)
		return nil;
	
	infinitif = [infinitif stringByReplacingOccurrencesOfString:@"To " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, infinitif.length - 1)];
	[infinitif stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Verb"];
	request.fetchLimit = 1;
	request.predicate = [NSPredicate predicateWithFormat:@"infinitif CONTAINS[cd] %@", infinitif];
	return [self.managedObjectContext executeFetchRequest:request error:NULL].firstObject;
}

- (void)addVerb:(Verb *)verb
{
	[[self mutableSetValueForKey:@"verbs"] addObject:verb];
	
	[self.managedObjectContext save:NULL];
}

- (void)removeVerb:(Verb *)verb
{
	[[self mutableSetValueForKey:@"verbs"] removeObject:verb];
	
	[self.managedObjectContext save:NULL];
}

@end
