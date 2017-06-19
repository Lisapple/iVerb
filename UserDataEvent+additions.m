//
//  UserDataEvent+additions.m
//  iVerb
//
//  Created by Max on 19/06/2017.
//
//

#import "UserDataEvent+additions.h"

@implementation UserDataEvent (additions)

- (NSUInteger)hash
{
	return self.timestamp.hash;
}

- (BOOL)isEqual:(id)object
{
	UserDataEvent * const event = (UserDataEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [self.timestamp isEqualToDate:event.timestamp];
}

@end


@implementation UDPlaylistEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.playlistID.hash ^ self.playlistName.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistEvent * const event = (UDPlaylistEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	if (self.playlistID && event.playlistID)
		return [super isEqual:event]
			&& [self.playlistID isEqual:event.playlistID];
	
	return [super isEqual:event]
		&& [self.playlistName isEqualToString:event.playlistName];
}

@end

@implementation UDPlaylistCreateEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.name.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistCreateEvent * const event = (UDPlaylistCreateEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.name isEqual:self.name];
}

@end

@implementation UDPlaylistRenameEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.oldName.hash ^ self.name.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistRenameEvent * const event = (UDPlaylistRenameEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.oldName isEqual:self.oldName]
		&& [self.name isEqual:self.name];
}

@end

@implementation UDPlaylistAddVerbEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.infinitif.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistRenameEvent * const event = (UDPlaylistRenameEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.infinitif isEqual:self.infinitif];
}

@end

@implementation UDPlaylistRemoveVerbEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.infinitif.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistRenameEvent * const event = (UDPlaylistRenameEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.infinitif isEqual:self.infinitif];
}

@end


@implementation UDVerbEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.infinitif.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistRenameEvent * const event = (UDPlaylistRenameEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.infinitif isEqual:self.infinitif];
}

@end

@implementation UDVerbAddNoteEvent (additions)

- (NSUInteger)hash
{
	return super.hash ^ self.note.hash;
}

- (BOOL)isEqual:(id)object
{
	UDPlaylistRenameEvent * const event = (UDPlaylistRenameEvent *)object;
	if (![event isKindOfClass:self.class])
		return [super isEqual:event];
	
	return [super isEqual:event]
		&& [self.note isEqual:self.note];
}

@end
