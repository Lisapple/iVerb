//
//  EditableTableViewCell.h
//  iVerb
//
//  Created by Max on 25/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditableTableViewCell;
@protocol EditableTableViewCellDelegate

- (void)editableCellDidBeginEditing:(EditableTableViewCell *)cell;
- (void)editableCellDidEndEditing:(EditableTableViewCell *)cell;

@end

@interface EditableTableViewCell : UITableViewCell <UITextFieldDelegate>
{
	@private
	UITextField * _textField;
}
@property (nonatomic, strong) NSObject <EditableTableViewCellDelegate> * delegate;
@property (nonatomic, strong) NSString * fieldValue;

@end
