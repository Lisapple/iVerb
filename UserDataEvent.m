//
//  UserDataEvent.m
//  iVerb
//
//  Created by Max on 20/04/2017.
//
//

#import "UserDataEvent.h"
#import "ManagedObjectContext.h"

#import "NSManagedObject+addition.h"

@implementation UserDataEvent

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)init
{
	if ((self = [super init])) {
		_timestamp = [NSDate date];
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super init])) {
		_timestamp = [aDecoder decodeObjectOfClass:NSDate.class
											forKey:SelectorName(timestamp)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_timestamp forKey:SelectorName(timestamp)];
}

@end


@implementation UDPlaylistEvent

- (instancetype)initWithPlaylist:(Playlist *)playlist;
{
	if ((self = [super init])) {
		_playlistID = playlist.permanentObjectID ?: playlist.objectID;
		_playlistName = playlist.name;
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		NSString * const stringRepresentation = [aDecoder decodeObjectOfClass:NSString.class
																	   forKey:SelectorName(playlistID)];
		_playlistID = [[ManagedObjectContext sharedContext] objectIDWithRepresentation:stringRepresentation];
		_playlistName = [aDecoder decodeObjectOfClass:NSString.class
											   forKey:SelectorName(playlistName)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_playlistID.stringReprentation forKey:SelectorName(playlistID)];
	[aCoder encodeObject:_playlistName forKey:SelectorName(playlistName)];
}

- (Playlist *)playlist
{
	if (_playlistID)
		return [Playlist playlistWithObjectID:_playlistID];
	
	if (_playlistName) // For migration only, try finding with the name
		return [Playlist playlistWithName:_playlistName];
	
	return nil;
}

@end

@implementation UDPlaylistCreateEvent

- (instancetype)initWithPlaylist:(Playlist *)playlist;
{
	if ((self = [super initWithPlaylist:playlist])) {
		_name = playlist.name;
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_name = [aDecoder decodeObjectOfClass:NSString.class forKey:SelectorName(name)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_name forKey:SelectorName(name)];
}

- (NSString *)name
{
	return _name ?: self.playlist.name ?: self.playlistName;
}

@end

@implementation UDPlaylistRenameEvent

- (instancetype)initWithPlaylist:(Playlist *)playlist;
{
	if ((self = [super initWithPlaylist:playlist])) {
		_name = playlist.name;
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_oldName = [aDecoder decodeObjectOfClass:NSString.class forKey:@"name"];
		_name = [aDecoder decodeObjectOfClass:NSString.class forKey:@"currentName"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_oldName forKey:@"name"];
	[aCoder encodeObject:_name forKey:@"currentName"];
}

- (NSString *)name
{
	return _name ?: self.playlist.name ?: self.playlistName;
}

@end

@implementation UDPlaylistDeleteEvent

@end

@implementation UDPlaylistAddVerbEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_infinitif = [aDecoder decodeObjectOfClass:NSString.class
											forKey:SelectorName(infinitif)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_infinitif forKey:SelectorName(infinitif)];
}

@end

@implementation UDPlaylistRemoveVerbEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_infinitif = [aDecoder decodeObjectOfClass:NSString.class
											forKey:SelectorName(infinitif)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_infinitif forKey:SelectorName(infinitif)];
}

@end


@implementation UDVerbEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_infinitif = [aDecoder decodeObjectOfClass:NSString.class
											forKey:SelectorName(infinitif)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_infinitif forKey:SelectorName(infinitif)];
}

@end

@implementation UDVerbAddNoteEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_note = [aDecoder decodeObjectOfClass:NSString.class
									   forKey:SelectorName(note)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_note forKey:SelectorName(note)];
}

@end

@implementation UDVerbRemoveNoteEvent

@end
