//
//  IndexBarTableView.m
//  IndexBar
//
//  Created by Max on 20/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IndexBarTableView.h"

@implementation IndexBarTableView

- (void)setDataSource:(id <UITableViewDataSource, IndexBarTableViewDataSource>)dataSource
{
	super.dataSource = dataSource;
	
	if ([dataSource respondsToSelector:@selector(sectionIndexTitlesForIndexBarTableView:)]) {
		NSArray * array = [dataSource sectionIndexTitlesForIndexBarTableView:self];
		
		if (array.count > 0) {
			CGRect frame = CGRectMake(self.frame.size.width - 30., 44. + 10., 28., self.frame.size.height - (2. * 10.) - 44.);
			indexBar = [[IndexBar alloc] initWithFrame:frame];
			indexBar.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin);
			[indexBar setLetters:array];
			[self.superview addSubview:indexBar];
			
			indexBar.delegate = self;
		}
	}
}

- (void)reloadSectionIndexTitles
{
	[indexBar removeFromSuperview];
	
	if ([self.dataSource respondsToSelector:@selector(sectionIndexTitlesForIndexBarTableView:)]) {
		NSArray * array = [(id <UITableViewDataSource, IndexBarTableViewDataSource>)self.dataSource sectionIndexTitlesForIndexBarTableView:self];
		
		if (array.count > 0) {
			CGRect frame = CGRectMake(self.frame.size.width - 30., 44. + 10., 28., self.frame.size.height - (2. * 10.) - 44.);
			indexBar = [[IndexBar alloc] initWithFrame:frame];
			indexBar.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin);
			[indexBar setLetters:array];
			
			[indexBar removeFromSuperview];
			[self.superview addSubview:indexBar];
			
			indexBar.delegate = self;
		}
	}
	
	[super reloadSectionIndexTitles];
}

- (void)drawRect:(CGRect)rect
{
	[indexBar update];
	
	[super drawRect:rect];
}

- (void)indexBarDidSelectIndex:(NSInteger)index
{
	if (index != NSNotFound) {
		if ([(NSObject <IndexBarTableViewDataSource> *)self.dataSource respondsToSelector:@selector(indexBarTableView:sectionForSectionIndexTitle:atIndex:)]) {
			NSString * indexTitle = nil;
			if ([(id <UITableViewDataSource, IndexBarTableViewDataSource>)self.dataSource respondsToSelector:@selector(sectionIndexTitlesForIndexBarTableView:)])
				indexTitle = [[(id <UITableViewDataSource, IndexBarTableViewDataSource>)self.dataSource sectionIndexTitlesForIndexBarTableView:self] objectAtIndex:index];
			
			[(NSObject <IndexBarTableViewDataSource> *)self.dataSource indexBarTableView:self
															 sectionForSectionIndexTitle:indexTitle
																				 atIndex:index];
			
		}
	}
}

@end
