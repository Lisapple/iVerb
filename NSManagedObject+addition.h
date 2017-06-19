//
//  NSManagedObject+addition.h
//  iVerb
//
//  Created by Max on 17/04/2017.
//
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObjectID (addition)

@property (nonatomic, strong, readonly) NSString * stringReprentation;

@end

@interface NSManagedObject (addition)

+ (instancetype)instanciateInContext:(NSManagedObjectContext *)context;

- (nullable NSManagedObjectID *)permanentObjectID;

@end

@interface NSManagedObjectContext (addition)

- (nullable NSManagedObjectID *)objectIDWithRepresentation:(NSString *)stringRepresentation;

@end

NS_ASSUME_NONNULL_END
