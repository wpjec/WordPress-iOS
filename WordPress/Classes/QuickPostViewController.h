//
//  QuickPostViewController.h
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogSelectorButton.h"

@class SidebarViewController;

@interface QuickPostViewController : UIViewController<BlogSelectorButtonDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, weak) SidebarViewController *sidebarViewController;

@end
