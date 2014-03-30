//
//  IndexBar.h
//  IndexBar
//
//  Created by Max on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IndexBarDelegate

- (void)indexBarDidSelectIndex:(NSInteger)index;

@end

@interface IndexBar : UIView
{
	id <IndexBarDelegate> delegate;
	
	@private
	NSArray * _letters;
	UIColor * _backgroundColor;
	
	NSMutableArray * _letterViews;
}

@property (nonatomic, retain) id <IndexBarDelegate> delegate;

- (void)setLetters:(NSArray *)letters;

- (void)update;

@end
