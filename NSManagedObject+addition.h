//
//  NSManagedObject+addition.h
//  iVerb
//
//  Created by Max on 17/04/2017.
//
//

@import CoreData;

@interface NSManagedObject (addition)

+ (instancetype)instanciateInContext:(NSManagedObjectContext *)context;

@end
