//
//  UserDataEvent.h
//  iVerb
//
//  Created by Max on 20/04/2017.
//
//

@import Foundation;

#import "Verb.h"

@interface UserDataEvent : NSObject <NSSecureCoding>

@property (nonatomic, strong, readonly) NSDate * timestamp;

@end


@interface /* abstract */ UDPlaylistEvent : UserDataEvent

@property (nonatomic, strong) NSString * playlistName;

@end

@interface UDPlaylistCreateEvent : UDPlaylistEvent

@end

@interface UDPlaylistRenameEvent : UDPlaylistEvent

@property (nonatomic, strong) NSString * originalName;

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
