//
//  Verb.h
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Playlist;
@class Quote;

NS_ASSUME_NONNULL_BEGIN

@interface Verb : NSManagedObject

@property (nonatomic, strong) NSString * infinitif, * past, * pastParticiple;
@property (nonatomic, strong, nullable) NSString * definition, * example;
@property (nonatomic, strong, nullable) NSString * note;

@property (nonatomic, strong, nullable) NSString * components;

@property (nonatomic, strong, nullable) NSDate * lastUse;

@property (nonatomic, strong) NSSet <Playlist *> * playlists;
@property (nonatomic, strong, nullable) Quote * quote;

@property (nonatomic, readonly) BOOL isBookmarked;

+ (Verb * _Nullable)lastUsedVerb;

- (BOOL)isBasicVerb;

- (void)addToPlaylist:(Playlist *)playlist;
- (void)removePlaylist:(Playlist *)playlist;

/**
 Same as `definition' with the first "To" and occurences of " to " removed.
 @discussion Use this property, instead of `definition', when searching to exclude irrevelant results when searching for "to".
 */
- (NSString *)searchableDefinition;

@end

NS_ASSUME_NONNULL_END
