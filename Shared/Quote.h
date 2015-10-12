//
//  Quote.h
//  iVerb
//
//  Created by Max on 06/10/15.
//
//

#import <CoreData/CoreData.h>

#import "Verb.h"

@class Verb;

@interface Quote : NSManagedObject

@property (nonatomic, strong) NSString * infinitif, * past, * pastParticiple;
@property (nonatomic, strong) Verb * verb;

- (NSString *)infinitifDescription;
- (NSString *)infinitifAuthor;

- (NSString *)pastDescription;
- (NSString *)pastAuthor;

- (NSString *)pastParticipleDescription;
- (NSString *)pastParticipleAuthor;

@end
