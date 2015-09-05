//
//  EditableTableViewCell.m
//  iVerb
//
//  Created by Max on 25/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "EditableTableViewCell.h"

@implementation EditableTableViewCell

@synthesize delegate = _delegate;
@synthesize fieldValue = _fieldValue;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		
		self.backgroundColor = [UIColor whiteColor];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		CGFloat height = self.bounds.size.height;
		CGRect rect = CGRectMake(15., (height - 26) / 2 + 2, 200., 26.);
		_textField = [[UITextField alloc] initWithFrame:rect];
		_textField.borderStyle = UITextBorderStyleNone;
		_textField.placeholder = @"New List";
		_textField.textColor = [UIColor darkGrayColor];
		_textField.font = [UIFont systemFontOfSize:17.];
		_textField.returnKeyType = UIReturnKeyDone;
		_textField.autocorrectionType = UITextAutocorrectionTypeNo;
		_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		
		_textField.delegate = self;
		
		[self addSubview:_textField];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(textFieldDidChange:)
													 name:UITextFieldTextDidChangeNotification 
												   object:nil];
    }
    return self;
}

- (void)setFieldValue:(NSString *)fieldValue
{
	_fieldValue = fieldValue;
	
	_textField.text = _fieldValue;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ([_delegate respondsToSelector:@selector(editableCellDidBeginEditing:)]) {
		[_delegate editableCellDidBeginEditing:self];
	}
}

- (void)textFieldDidChange:(NSNotification *)notification
{
	UITextField * textField = notification.object;
	_fieldValue = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if ([(NSObject *)_delegate respondsToSelector:@selector(editableCellDidEndEditing:)]) {
		[_delegate editableCellDidEndEditing:self];
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
