//
//  Verb.h
//  iVerb
//
//  Created by Max on 26/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const VerbDidUpdateNoteNotification; // object = verb
extern NSString * const VerbDidRemoveNoteNotification; // object = verb

@class Playlist;
@class Quote;
@interface Verb : NSManagedObject

@property (nonatomic, strong) NSString * infinitif, * past, * pastParticiple;
@property (nonatomic, strong, nullable) NSString * definition;
@property (nonatomic, strong, nullable) NSString * example DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong, nullable) NSString * note;

@property (nonatomic, strong, nullable) NSString * components;

@property (nonatomic, strong, nullable) NSDate * lastUse;

@property (nonatomic, strong) NSSet <Playlist *> * playlists;
@property (nonatomic, strong, nullable) Quote * quote;

@property (nonatomic, readonly) BOOL isBookmarked;

+ (Verb * _Nullable)lastUsedVerb;

- (BOOL)isBasicVerb;

/**
 Same as `definition' with the first "To" and occurences of " to " removed.
 @discussion Use this property, instead of `definition', when searching to exclude irrevelant results when searching for "to".
 */
- (NSString *)searchableDefinition;

@end

NS_ASSUME_NONNULL_END
