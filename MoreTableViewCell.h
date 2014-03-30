//
//  MoreTableViewCell.h
//  iVerb
//
//  Created by Maxime Leroy on 2/5/13.
//
//

#import <UIKit/UIKit.h>

#import "MyTableViewCell.h"

@interface _MoreTableViewCellButton : UIButton

@end


@interface MoreTableViewCell : MyTableViewCell
{
	_MoreTableViewCellButton * moreButton;
}

@property (nonatomic, strong) NSObject * moreTarget;
@property (nonatomic, assign) SEL moreAction;

@property (nonatomic, assign) BOOL showsMoreButton;

@end
