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

NSString * const VerbDidUpdateNoteNotification = @"VerbDidUpdateNoteNotification";
NSString * const VerbDidRemoveNoteNotification = @"VerbDidRemoveNoteNotification";

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

- (NSString *)noteKey
{
	return [NSString stringWithFormat:@"note_%@", self.infinitif];
}

- (NSString *)note
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:self.noteKey];
}

- (void)setNote:(NSString *)note
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([note stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
		[userDefaults setObject:note forKey:self.noteKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:VerbDidUpdateNoteNotification object:self];
	} else {
		[userDefaults removeObjectForKey:self.noteKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:VerbDidRemoveNoteNotification object:self];
	}
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
