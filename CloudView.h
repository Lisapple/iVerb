//
//  CloudView.h
//  CloudVerb
//
//  Created by Max on 06/02/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Verb.h"

@interface CloudLabel : UILabel

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, strong) Verb * verb;

@end


@interface CloudView : UIView
{
	CGFloat initialSpeed, speed, addedSpeed;
	CGFloat totalOffset;
	
	NSTimeInterval beginTimestamp;
	CGPoint beginPosition;
}

@property (nonatomic, assign) CGFloat totalWidth;

- (void)update;

@end