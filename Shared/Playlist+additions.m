//
//  Playlist+additions.m
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Playlist+additions.h"

#import "Verb.h"

#define kLastUsedPlaylist @"Last Used Playlist"

@implementation Playlist (additions)

static Playlist * _currentPlaylist = nil;

+ (Playlist *)currentPlaylist
{
	if (!_currentPlaylist) {
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * name = [userDefaults stringForKey:kLastUsedPlaylist];
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
		[userDefaults setObject:name forKey:kLastUsedPlaylist];
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
				CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:verb.infinitif domainIdentifier:@"verbs" attributeSet:attributeSet];
				[searchableItems addObject:item];
			}
			[[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:searchableItems completionHandler:completionHandler];
		});
	}
}

@end
