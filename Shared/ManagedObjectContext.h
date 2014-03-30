//
//  ManagedObjectContext.h
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ManagedObjectContext <NSObject>

- (NSManagedObjectContext *)managedObjectContext;

@end

@interface ManagedObjectContext : NSObject

+ (NSManagedObjectContext *)sharedContext;

@end
