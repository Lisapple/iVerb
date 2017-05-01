//
//  UserDataEvent.m
//  iVerb
//
//  Created by Max on 20/04/2017.
//
//

#import "UserDataEvent.h"

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

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_playlistName = [aDecoder decodeObjectOfClass:NSString.class
											   forKey:SelectorName(playlistName)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_playlistName forKey:SelectorName(playlistName)];
}

@end

@implementation UDPlaylistCreateEvent

@end

@implementation UDPlaylistRenameEvent

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_originalName = [aDecoder decodeObjectOfClass:NSString.class
											   forKey:SelectorName(name)];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_originalName forKey:SelectorName(name)];
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
