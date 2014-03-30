//
//  IndexBarTableView.h
//  IndexBar
//
//  Created by Max on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IndexBar.h"

@class IndexBarTableView;
@protocol IndexBarTableViewDataSource

- (NSArray *)sectionIndexTitlesForIndexBarTableView:(IndexBarTableView *)aTableView;
- (NSInteger)indexBarTableView:(IndexBarTableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;

@end

@interface IndexBarTableView : UITableView <IndexBarDelegate>
{
	IndexBar * indexBar;
}

@end
