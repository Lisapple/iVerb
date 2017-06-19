//
//  NSManagedObject+addition.m
//  iVerb
//
//  Created by Max on 17/04/2017.
//
//

#import "NSManagedObject+addition.h"

@implementation NSManagedObjectID (addition)

- (NSString *)stringReprentation
{
	return self.URIRepresentation.absoluteString;
}

@end


@implementation NSManagedObject (addition)

+ (instancetype)instanciateInContext:(NSManagedObjectContext *)context
{
	NSEntityDescription * entity = [NSEntityDescription entityForName:NSStringFromClass(self.class)
											   inManagedObjectContext:context];
	return [[self.class alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
}

- (nullable NSManagedObjectID *)permanentObjectID
{
	NSError * error = nil;
	if ([self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:&error]) {
		return self.objectID;
	}
	NSLog(@"Error when obtaining permanent object ID for %@: %@", self, error);
	return nil;
}

@end


@implementation NSManagedObjectContext (addition)

- (nullable NSManagedObjectID *)objectIDWithRepresentation:(NSString *)stringRepresentation
{
	NSURL * const uri = [NSURL URLWithString:stringRepresentation];
	if (uri)
		return [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:uri];
	return nil;
}

@end
