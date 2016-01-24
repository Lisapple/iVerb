//
//  QuizResult.h
//  iVerb
//
//  Created by Max on 22/01/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist;

@interface QuizResult : NSManagedObject

@property (nonatomic, retain) NSNumber * rightResponses;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * wrongResponses;
@property (nonatomic, retain) Playlist * playlist;

@end