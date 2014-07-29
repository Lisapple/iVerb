//
//  ActionSheet.h
//  iVerb
//
//  Created by Maxime Leroy on 3/23/13.
//
//

#import <UIKit/UIKit.h>

enum _ActionSheetButtonType {
	ActionSheetButtonTypeDefault,
	ActionSheetButtonTypeCancel,
	ActionSheetButtonTypeDelete
	};
typedef enum _ActionSheetButtonType ActionSheetButtonType;

@interface _ActionSheetButton : UIButton
{
}

@property (nonatomic, assign) ActionSheetButtonType type;
@property (nonatomic, strong) UIColor * titleColor;

@end


@class ActionSheet;
@protocol ActionSheetDelegate <NSObject>

@optional
- (void)actionSheet:(ActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)actionSheetCancel:(ActionSheet *)actionSheet;

@end


@interface ActionSheet : UIView
{
@private
	NSMutableArray * buttons;
	UIWindow * window;
	void (^usingBlock)(NSInteger buttonIndex);
}

@property (nonatomic, assign) id <ActionSheetDelegate> delegate;

- (id)initWithTitle:(NSString *)title delegate:(id <ActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (NSInteger)addButtonWithTitle:(NSString *)title;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;

- (void)showInView:(UIView *)view;
- (void)showInView:(UIView *)view usingBlock:(void (^)(NSInteger buttonIndex))block;

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end
