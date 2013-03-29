//
//  QuickPostButtonView.h
//  WordPress
//
//  Created by Eric Johnson on 6/19/12.
//

#import <UIKit/UIKit.h>

@protocol QuickPostButtonViewDelegate;

@interface QuickPostButtonView : UIView

@property (nonatomic, strong) id<QuickPostButtonViewDelegate>delegate;

- (void)showSuccess;
- (void)showProgress:(BOOL)show animated:(BOOL)animated;

@end

@protocol QuickPostButtonViewDelegate <NSObject>
- (void)quickPostButtonViewTapped:(QuickPostButtonView *)sender;
@end