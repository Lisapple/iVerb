//
//  NSManagedObject+addition.m
//  iVerb
//
//  Created by Max on 17/04/2017.
//
//

#import "NSManagedObject+addition.h"

@implementation NSManagedObject (addition)

+ (instancetype)instanciateInContext:(NSManagedObjectContext *)context
{
	NSEntityDescription * entity = [NSEntityDescription entityForName:NSStringFromClass(self.class)
											   inManagedObjectContext:context];
	return [[self.class alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
}

@end
