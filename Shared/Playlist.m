//
//  Playlist.m
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist.h"
#import "ManagedObjectContext.h"

@implementation Playlist

@dynamic name;
@dynamic creationDate;
@dynamic verbs;

@dynamic isDefaultPlaylist;

+ (Playlist *)lastUsedPlaylist
{
	// @TODO: implements
	return nil;
}

+ (Playlist *)allVerbsPlaylist
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	[request setPredicate:[NSPredicate predicateWithFormat:@"name == '_ALL_VERBS_'"]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	if (playlists.count > 0)
		return playlists[0];
	
	return nil;
}

+ (Playlist *)basicVerbsPlaylist
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	[request setPredicate:[NSPredicate predicateWithFormat:@"name == '_BASICS_VERBS_'"]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	if (playlists.count > 0)
		return playlists[0];
	
	return nil;
}

+ (Playlist *)bookmarksPlaylist
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	[request setPredicate:[NSPredicate predicateWithFormat:@"name == '_BOOKMARKS_'"]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	if (playlists.count > 0)
		return playlists[0];
	
	return nil;
}

+ (Playlist *)historyPlaylist
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	[request setPredicate:[NSPredicate predicateWithFormat:@"name == '_HISTORY_'"]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	if (playlists.count > 0)
		return playlists[0];
	
	return nil;
}

+ (NSArray *)defaultPlaylist
{
	return [Playlist defaultPlaylists];
}

+ (NSArray *)defaultPlaylists
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	[request setPredicate:[NSPredicate predicateWithFormat:@"creationDate == NULL"]];
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	[request setSortDescriptors:@[sortDescriptor]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	return playlists;
}

+ (NSArray *)userPlaylists
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	[request setPredicate:[NSPredicate predicateWithFormat:@"creationDate != NULL"]];
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	[request setSortDescriptors:@[sortDescriptor]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	return playlists;
}

+ (Playlist *)playlistWithName:(NSString *)name
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
	request.predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	request.fetchLimit = 1;
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
	[request setSortDescriptors:@[sortDescriptor]];
	
	NSArray * playlists = [context executeFetchRequest:request
												 error:NULL];
	
	if (playlists.count > 0)
		return playlists[0];
	
	return nil;
}

- (BOOL)canBeModified
{
	return (![self.name isEqualToString:@"_ALL_VERBS_"] && ![self.name isEqualToString:@"_BASICS_VERBS_"]);
}

- (BOOL)isBasicPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:@"_BASICS_VERBS_"]);
}

- (BOOL)isAllVerbsPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:@"_ALL_VERBS_"]);
}

- (BOOL)isHistoryPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:@"_HISTORY_"]);
}

- (BOOL)isBookmarksPlaylist
{
	return (self.isDefaultPlaylist && [self.name isEqualToString:@"_BOOKMARKS_"]);
}

- (BOOL)isDefaultPlaylist
{
	return (self.creationDate == nil);
}

- (BOOL)isUserPlaylist
{
	return ![self isDefaultPlaylist];
}

/*
- (NSArray *)verbs
{
	return [[self mutableSetValueForKey:@"verbs"] allObjects];
}
*/

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
