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

@end
