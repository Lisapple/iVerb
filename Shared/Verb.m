//
//  Verb.m
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Verb.h"
#import "Playlist.h"

#import "ManagedObjectContext.h"

@implementation Verb

@dynamic infinitif, past, pastParticiple;
@dynamic definition, example;
@dynamic note;
@dynamic components;
@dynamic lastUse;
@dynamic playlists;
@dynamic quote;

@dynamic isBookmarked;

+ (Verb *)lastUsedVerb
{
	NSManagedObjectContext * context = [ManagedObjectContext sharedContext];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Verb"];
	request.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUse" ascending:NO];
	request.sortDescriptors = @[ sortDescriptor ];
	return [context executeFetchRequest:request error:NULL].firstObject;
}

- (BOOL)isBookmarked
{
	return [[self mutableSetValueForKeyPath:@"playlists.name"] containsObject:kPlaylistBookmarksName];
}

- (BOOL)isBasicVerb
{
	/* "components" return the composition of the verb separated by dot ("."), for non-composed (basic) verbs, "components" have the same value than infinitif */
	return (!self.components || [self.components componentsSeparatedByString:@"."].count == 1);
}

- (Playlist *)playlist
{
	return [self mutableSetValueForKey:@"playlists"].anyObject;
}

- (void)addToPlaylist:(Playlist *)playlist
{
	if (playlist) {
		if (![self.playlists containsObject:playlist]) {
			[[self mutableSetValueForKey:@"playlists"] addObject:playlist];
			[self.managedObjectContext save:NULL];
		}
	}
}

- (void)removePlaylist:(Playlist *)playlist
{
	if (playlist) {
		[[self mutableSetValueForKey:@"playlists"] removeObject:playlist];
		[self.managedObjectContext save:NULL];
	}
}

- (NSString *)note
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"note_%@", self.infinitif];
	return [userDefaults stringForKey:key];
}

- (NSString *)searchableDefinition
{
	if (self.definition.length > 2) {
		NSString * definition = [self.definition substringFromIndex:2];
		return [definition stringByReplacingOccurrencesOfString:@" to " withString:@""];
	}
	return self.definition;
}

@end
