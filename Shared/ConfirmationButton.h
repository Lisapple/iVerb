//
//  ConfirmationButton.h
//  iVerb
//
//  Created by Max on 07/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfirmationButton : UIButton
{
	UITableViewCell * tableViewCell;
}

@property (nonatomic, copy) NSString * title;

- (id)initWithCell:(UITableViewCell *)cell;

@end
