//
//  ManagedObjectContext.m
//  iVerb
//
//  Created by Max on 27/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ManagedObjectContext.h"

@implementation ManagedObjectContext

+ (NSManagedObjectContext *)sharedContext
{
	id <ManagedObjectContext> app = (id <ManagedObjectContext>)[[UIApplication sharedApplication] delegate];
	return [app managedObjectContext];
}

@end
