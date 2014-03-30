//
//  Verb.m
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Verb.h"

#import "ManagedObjectContext.h"

@implementation Verb

@dynamic infinitif, past, pastParticiple;
@dynamic definition, example;
@dynamic note;
@dynamic components;
@dynamic lastUse;
@dynamic playlists;

@dynamic isBookmarked;

+ (Verb *)lastUsedVerb
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Verb"];
	request.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
	//request.fetchLimit = 1;
	
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUse" ascending:NO];
	request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	
	NSArray * verbs = [context executeFetchRequest:request
												 error:NULL];
	
	if (verbs.count > 0)
		return [verbs objectAtIndex:0];
	
	return nil;
}

- (BOOL)isBookmarked
{
	return [[self mutableSetValueForKeyPath:@"playlists.name"] containsObject:@"_BOOKMARKS_"];
}

- (BOOL)isBasicVerb
{
	/* "components" return the composition of the verb separated by dot ("."), for non-composed (basic) verbs, "components" have the same value than infinitif */
	return ([self.components componentsSeparatedByString:@"."].count == 1);
}

- (Playlist *)playlist
{
	NSSet * playlists = [self mutableSetValueForKey:@"playlists"];
	if (playlists.count > 0)
		return [[playlists allObjects] objectAtIndex:0];
	
	return nil;
}

- (void)addToPlaylist:(Playlist *)playlist
{
	if (playlist) {
		if (![self.playlists containsObject:playlist]) {
			[[self mutableSetValueForKey:@"playlists"] addObject:playlist];
			[self.managedObjectContext save:NULL];
		}
		
		/*
		NSMutableSet * playlistsName = [self mutableSetValueForKeyPath:@"playlists.name"];
		if (![playlistsName containsObject:playlist.name]) {
			[self.playlists addObject:playlist];
			[self.managedObjectContext save:NULL];
		}
		*/
	}
}

- (void)removePlaylist:(Playlist *)playlist
{
	if (playlist) {
		[[self mutableSetValueForKey:@"playlists"] removeObject:playlist];
		[self.managedObjectContext save:NULL];
		
		/*
		NSMutableSet * playlistsName = [self mutableSetValueForKeyPath:@"playlists.name"];
		if ([playlistsName containsObject:playlist.name]) {
			[self.playlists removeObject:playlist];
			[self.managedObjectContext save:NULL];
		}
		 */
	}
}

- (NSString *)note
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"note_%@", self.infinitif];
	return [userDefaults stringForKey:key];
}

@end
