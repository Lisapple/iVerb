//
//  UserDataEvent.h
//  iVerb
//
//  Created by Max on 20/04/2017.
//
//

@import Foundation;

#import "Verb.h"
#import "Playlist.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserDataEvent : NSObject <NSSecureCoding>

@property (nonatomic, strong, readonly) NSDate * timestamp;

@end


@interface /* abstract */ UDPlaylistEvent : UserDataEvent

/// The unique object ID of the playlist.
@property (nonatomic, strong, readonly) NSManagedObjectID * playlistID;

/// A reference to the playlist in the current managed context; nil if no playlist with matching ID found.
@property (nonatomic, strong, readonly, nullable) Playlist * playlist;

@property (nonatomic, strong, nullable) NSString * playlistName DEPRECATED_MSG_ATTRIBUTE("Migration from 2.6 only. Use 'playlist.name' or 'playlistID' instead.");

- (instancetype)initWithPlaylist:(Playlist *)playlist;

@end

@interface UDPlaylistCreateEvent : UDPlaylistEvent

@property (nonatomic, strong) NSString * name;

@end

@interface UDPlaylistRenameEvent : UDPlaylistEvent

@property (nonatomic, strong) NSString * oldName;
@property (nonatomic, strong) NSString * name;

@end

@interface UDPlaylistDeleteEvent : UDPlaylistEvent

@end

@interface UDPlaylistAddVerbEvent : UDPlaylistEvent

@property (nonatomic, strong) NSString * infinitif;

@end

@interface UDPlaylistRemoveVerbEvent : UDPlaylistEvent

@property (nonatomic, strong) NSString * infinitif;

@end


@interface /* abstract */ UDVerbEvent : UserDataEvent

@property (nonatomic, strong) NSString * infinitif;

@end

@interface UDVerbAddNoteEvent : UDVerbEvent

@property (nonatomic, strong) NSString * note;

@end

@interface UDVerbRemoveNoteEvent : UDVerbEvent

@end

NS_ASSUME_NONNULL_END
