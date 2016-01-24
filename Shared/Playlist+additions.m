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

static Playlist * _currentPlaylist = nil;

+ (Playlist *)currentPlaylist
{
	if (!_currentPlaylist) {
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * name = [userDefaults stringForKey:LastUsedPlaylistKey];
		_currentPlaylist = [Playlist playlistWithName:name];
		if (!_currentPlaylist) {
			_currentPlaylist = [Playlist allVerbsPlaylist];
		}
	}
	
	return _currentPlaylist;
}

+ (void)setCurrentPlaylist:(Playlist *)playlist
{
	_currentPlaylist = playlist;
	
	NSString * name = _currentPlaylist.name;
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

- (void)buildingSpolightIndexWithCompletionHandler:(void (^ __nullable)(NSError * __nullable error))completionHandler
{
	if (NSClassFromString(@"CSSearchableIndex")) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableArray <CSSearchableItem *> * searchableItems = [[NSMutableArray alloc] initWithCapacity:self.verbs.count];
			for (Verb * verb in self.verbs) {
				CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];
				attributeSet.title = [@"To " stringByAppendingString:verb.infinitif];
				attributeSet.contentDescription = [NSString stringWithFormat:@"%@, %@\n%@", verb.past, verb.pastParticiple, verb.definition];
				attributeSet.keywords = @[ verb.infinitif, [attributeSet.contentDescription componentsSeparatedByString:@" "] ];
				
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
