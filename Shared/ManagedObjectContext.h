//
//  ManagedObjectContext.h
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@protocol ManagedObjectContext <NSObject>

- (NSManagedObjectContext *)managedObjectContext;

@end

@interface ManagedObjectContext : NSObject

+ (NSManagedObjectContext *)sharedContext;

@end

NS_ASSUME_NONNULL_END
