//
//  Verb.h
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Playlist.h"

@class Playlist;

@interface Verb : NSManagedObject

@property (nonatomic, strong) NSString * infinitif, * past, * pastParticiple;
@property (nonatomic, strong) NSString * definition, * example;
@property (nonatomic, strong) NSString * note;

@property (nonatomic, strong) NSString * components;

@property (nonatomic, strong) NSDate * lastUse;

@property (nonatomic, strong) NSSet * playlists;

@property (nonatomic, readonly) BOOL isBookmarked;

+ (Verb *)lastUsedVerb;

- (BOOL)isBasicVerb;

- (void)addToPlaylist:(Playlist *)playlist;
- (void)removePlaylist:(Playlist *)playlist;

@end