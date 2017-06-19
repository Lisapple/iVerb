//
//  Playlist+additions.m
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist+additions.h"

#import "Verb.h"
#import "NSManagedObject+addition.h"

@implementation Playlist (additions)

static Playlist * _lastSelectedPlaylist = nil;
static Playlist * _lastPlaylistSelectedToAddVerb = nil;

+ (nullable Playlist *)playlistForAction:(PlaylistAction)action
{
	switch (action) {
		case PlaylistActionSelect: {
			if (!_lastSelectedPlaylist) {
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				NSString * const name = [userDefaults stringForKey:UserDefaultsLastUsedPlaylistKey];
				_lastSelectedPlaylist = [Playlist playlistWithName:name];
				if (!_lastSelectedPlaylist)
					_lastSelectedPlaylist = [Playlist allVerbsPlaylist];
			}
			return _lastSelectedPlaylist;
		}
		case PlaylistActionAddTo: {
			NSString * const name = _lastPlaylistSelectedToAddVerb.name;
			// If the playlist is about to be deleted, the name is nil, return no playlist in this case. 
			return (name) ? [Playlist playlistWithName:name] : nil;
		}
		default: break;
	}
	return nil;
}

+ (void)setPlaylist:(nullable Playlist *)playlist forAction:(PlaylistAction)action
{
	if (action == PlaylistActionSelect) {
		_lastSelectedPlaylist = playlist;
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:playlist.name forKey:UserDefaultsLastUsedPlaylistKey];
		
		// Update shared default playlist content
		Playlist * sharedPlaylist = (playlist.verbs.count) ? playlist : [Playlist commonsVerbsPlaylist];
		[sharedPlaylist updateSharedVerbsFor:SharedDestinationWidget];
		
		// Update shortcut items
		UIApplication * app = [UIApplication sharedApplication];
		if ([app respondsToSelector:@selector(shortcutItems)] && app.shortcutItems.count >= 2) {
			NSMutableArray * shortcutItems = [app.shortcutItems subarrayWithRange:NSMakeRange(0, 2)].mutableCopy;
			if (playlist.name && playlist.isUserPlaylist && playlist.verbs.count > 0) {
				UIApplicationShortcutItem * shortcutItem = [[UIApplicationShortcutItem alloc] initWithType:@"com.lisacintosh.iverb.launch.quiz"
																							localizedTitle:@"Launch Quiz"
																						 localizedSubtitle:playlist.name
																									  icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay]
																								  userInfo:@{ @"playlist" : playlist.name }];
				[shortcutItems addObject:shortcutItem];
			}
			app.shortcutItems = shortcutItems;
		}
	}
	else if (action == PlaylistActionAddTo) {
		_lastPlaylistSelectedToAddVerb = playlist;
	}
}

+ (Playlist *)insertPlaylistWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context
{
	NSParameterAssert(name); NSParameterAssert(context);
	Playlist * playlist = [Playlist instanciateInContext:context];
	playlist.name = name;
	playlist.creationDate = [NSDate date];
	return playlist;
}

- (NSString *)localizedName
{
	if (self.isDefaultPlaylist)
		return NSLocalizedString(self.name, nil); // Translate "_ALL_VERBS_", "_COMMONS_", "_BOOKMARKS_" or "_HISTORY_"
	
	return self.name;
}

- (NSString *)HTMLFormat
{
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"infinitif" ascending:YES];
	NSArray * verbs = [self.verbs sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	NSMutableString * content = [NSMutableString stringWithCapacity:100 * verbs.count];
	
	// @TODO: check "verbs" count, if equal to zero, show a message
	int index = 0;
	for (Verb * verb in verbs) {
		[content appendFormat:
		 @"<tr class=\"%@\">"
			@"<td>%@</td>" @"<td>%@</td>" @"<td>%@</td>"
		 @"</tr>",
		 (index & 1)? @"gray": @"white", verb.infinitif, verb.past, verb.pastParticiple];
		index++;
	}
	
	NSMutableString * template = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"verbs_lists_template" ofType:@"html"]
																  encoding:NSUTF8StringEncoding error:NULL];
	
	CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
	[template replaceOccurrencesOfString:@"{{font-size}}" withString:[NSString stringWithFormat:@"%ldpx", (long)fontSize]
								options:0 range: NSMakeRange(0, template.length)];
	return [template stringByReplacingOccurrencesOfString:@"{{@}}" withString:content];
}

- (Verb *)verbWithInfinitif:(NSString *)infinitif
{
	if (!infinitif)
		return nil;
	
	infinitif = [infinitif stringByReplacingOccurrencesOfString:@"To " withString:@""
														options:NSCaseInsensitiveSearch
														  range:NSMakeRange(0, infinitif.length - 1)];
	[infinitif stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Verb"];
	request.fetchLimit = 1;
	request.predicate = [NSPredicate predicateWithFormat:@"infinitif LIKE[cd] %@", infinitif];
	Verb * verb = [self.managedObjectContext executeFetchRequest:request error:NULL].firstObject;
	if (!verb) {
		request.predicate = [NSPredicate predicateWithFormat:@"infinitif CONTAINS[cd] %@", infinitif];
		verb = [self.managedObjectContext executeFetchRequest:request error:NULL].firstObject;
	}
	return verb;
}

@end

@implementation Playlist (Spotlight)

- (void)buildingSpolightIndexWithCompletionHandler:(void (^)(NSError * error))completionHandler
{
	if (NSClassFromString(@"CSSearchableIndex")) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableArray <CSSearchableItem *> * searchableItems = [[NSMutableArray alloc] initWithCapacity:self.verbs.count];
			for (Verb * verb in self.verbs) {
				CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];
				attributeSet.title = [@"To " stringByAppendingString:verb.infinitif];
				attributeSet.contentDescription = [NSString stringWithFormat:@"%@, %@\n%@", verb.past, verb.pastParticiple, verb.definition];
				attributeSet.keywords = [[attributeSet.contentDescription componentsSeparatedByString:@" "] arrayByAddingObject:verb.infinitif];
				
				CGFloat scale = [UIScreen mainScreen].scale;
				NSString * imageName = (scale > 1) ? [NSString stringWithFormat:@"spotlight@%.0fx", scale] : @"spotlight";
				attributeSet.thumbnailURL = [[NSBundle mainBundle] URLForResource:imageName withExtension:@"png"];
				
				CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:verb.infinitif domainIdentifier:@"verbs" attributeSet:attributeSet];
				[searchableItems addObject:item];
			}
			[[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:searchableItems completionHandler:completionHandler];
		});
	}
}

@end

@implementation Playlist (SharedPlaylist)

- (void)updateSharedVerbsFor:(SharedDestination)destination
{
	
	switch (destination) {
		case SharedDestinationWidget: {
			NSMutableDictionary * verbs = [[NSMutableDictionary alloc] initWithCapacity:self.verbs.count];
			for (Verb * verb in self.verbs) {
				verbs[verb.infinitif] = [NSString stringWithFormat:@"%@|%@|%@",
										 verb.past, verb.pastParticiple, verb.definition];
			}
			
			NSUserDefaults * const sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.iverb"];
			[sharedDefaults setObject:verbs forKey:UserDefaultsWidgetSharedVerbsKey];
			[sharedDefaults setObject:(self.isUserPlaylist) ? self.name : nil
							   forKey:UserDefaultsLastUsedPlaylistKey]; // Share playlist only from user playlist (these can launch quiz)
		}
			break;
		case SharedDestinationWatch: {
			if (NSClassFromString(@"WCSession") && [WCSession isSupported] && [WCSession defaultSession].isWatchAppInstalled) {
				
				NSMutableDictionary * verbs = [[NSMutableDictionary alloc] initWithCapacity:self.verbs.count];
				for (Verb * verb in self.verbs) {
					verbs[verb.infinitif] = [NSString stringWithFormat:@"%@|%@|%@|%d|%d",
											 verb.past, verb.pastParticiple, verb.definition,
											 verb.isBookmarked, (verb.note.length > 0)];
				}
				NSDictionary <NSString *, id> * context = @{ @"verbs" : verbs };
				NSError * error = nil;
				BOOL success = [[WCSession defaultSession] updateApplicationContext:context error:&error];
				if (!success)
					NSLog(@"error: %@", error.localizedDescription);
			}
		}
	}
	
}

@end
