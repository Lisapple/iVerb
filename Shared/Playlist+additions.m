//
//  Playlist+additions.m
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist+additions.h"

#import "Verb.h"

NSString * const LastUsedPlaylistKey = @"Last Used Playlist";

/**
 A dictionary with all verbs from the current playlist.
 The format is [infinitif] = "infinitif|past|pastParticiple|definition"
 */
NSString * const SharedVerbsKey = @"Shared Verbs";

@implementation Playlist (additions)

static Playlist * _lastSelectedPlaylist = nil;
static Playlist * _lastPlaylistSelectedToAddVerb = nil;

+ (nullable Playlist *)playlistForAction:(PlaylistAction)action
{
	switch (action) {
		case PlaylistActionSelect: {
			if (!_lastSelectedPlaylist) {
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				NSString * name = [userDefaults stringForKey:LastUsedPlaylistKey];
				_lastSelectedPlaylist = [Playlist playlistWithName:name];
				if (!_lastSelectedPlaylist) {
					_lastSelectedPlaylist = [Playlist allVerbsPlaylist];
				}
			}
			return _lastSelectedPlaylist;
		}
		case PlaylistActionAddTo:
			return _lastPlaylistSelectedToAddVerb;
		default: break;
	}
	return nil;
}

+ (void)setPlaylist:(nullable Playlist *)playlist forAction:(PlaylistAction)action
{
	if /**/ (action == PlaylistActionSelect) {
		_lastSelectedPlaylist = playlist;
		
		NSString * name = playlist.name;
		if (name) {
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			[userDefaults setObject:name forKey:LastUsedPlaylistKey];
			
			NSMutableDictionary * verbs = [[NSMutableDictionary alloc] initWithCapacity:playlist.verbs.count];
			for (Verb * verb in playlist.verbs) {
				verbs[verb.infinitif] = [NSString stringWithFormat:@"%@|%@|%@|%@",
										 verb.infinitif, verb.past, verb.pastParticiple, verb.definition];
			}
			NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.iverb"];
			[sharedDefaults setObject:verbs forKey:SharedVerbsKey];
			[sharedDefaults setObject:name forKey:LastUsedPlaylistKey];
		}
		
		UIApplication * app = [UIApplication sharedApplication];
		if ([app respondsToSelector:@selector(shortcutItems)] && app.shortcutItems.count >= 2) {
			NSMutableArray * shortcutItems = [app.shortcutItems subarrayWithRange:NSMakeRange(0, 2)].mutableCopy;
			if (name && playlist.isUserPlaylist) {
				UIApplicationShortcutItem * shortcutItem = [[UIApplicationShortcutItem alloc] initWithType:@"com.lisacintosh.iverb.launch.quiz"
																							localizedTitle:@"Launch Quiz"
																						 localizedSubtitle:name
																									  icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay]
																								  userInfo:@{ @"playlist" : name }];
				[shortcutItems addObject:shortcutItem];
			}
			app.shortcutItems = shortcutItems;
		}
	}
	else if (action == PlaylistActionAddTo) {
		_lastPlaylistSelectedToAddVerb = playlist;
	}
}

- (NSString *)localizedName
{
	return NSLocalizedString(self.name, nil); // Convert "_ALL_VERBS_", "_BASICS_VERBS_", "_BOOKMARKS_", "_HISTORY_" to correct title, skip user's playlists title
}

- (NSString *)HTMLFormat
{
	NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"infinitif" ascending:YES];
	NSArray * verbs = [self.verbs sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	NSMutableString * content = [NSMutableString stringWithCapacity:100 * verbs.count];
	
	// @TODO: check "verbs" count, if equal to zero, show a message
	int index = 0;
	for (Verb * verb in verbs) {
		/* <tr class="(white|gray)">
		 * <td>(infinitif)</td>
		 * <td>(past)</td>
		 * <td>(past participle)</td>
		 * </tr>
		 */
		[content appendFormat:@"<tr class=\"%@\"><td>%@</td><td>%@</td><td>%@</td></tr>", (index & 1)? @"gray": @"white", verb.infinitif, verb.past, verb.pastParticiple];
		index++;
	}
	
	NSString * template = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"verbs_lists_template" ofType:@"html"]
													encoding:NSUTF8StringEncoding
													   error:NULL];
	return [template stringByReplacingOccurrencesOfString:@"{{@}}" withString:content];
}

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
