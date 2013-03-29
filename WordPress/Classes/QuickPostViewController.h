//
//  QuickPostViewController.h
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogSelectorButton.h"

typedef enum {
    QuickPostTypeUnknown = 0,
    QuickPostTypeText,
    QuickPostTypePhoto
} QuickPostType;

@class SidebarViewController;

@interface QuickPostViewController : UIViewController<BlogSelectorButtonDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, assign) UIImagePickerControllerSourceType imageSourceType;
@property (nonatomic, assign) QuickPostType postType;
@property (nonatomic, weak) SidebarViewController *sidebarViewController;
@property (nonatomic, assign) BOOL useCameraPlus;

- (id)initWithPostType:(QuickPostType)postType imageSourceType:(UIImagePickerControllerSourceType)imageSourceType useCameraPlus:(BOOL)useCameraPlus;

@end
