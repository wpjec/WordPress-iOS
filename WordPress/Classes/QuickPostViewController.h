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
    QuickPostImageSourceTypePhotoLibrary = UIImagePickerControllerSourceTypePhotoLibrary,
    QuickPostImageSourceTypeCamera = UIImagePickerControllerSourceTypeCamera,
    QuickPostImageSourceTypePhotosAlbum = UIImagePickerControllerSourceTypeSavedPhotosAlbum,
    QuickPostImageSourceTypeNone
} QuickPostImageSourceType;

@class SidebarViewController;

@interface QuickPostViewController : UIViewController

@property (nonatomic, assign) QuickPostImageSourceType imageSourceType;
@property (nonatomic, weak) SidebarViewController *sidebarViewController;
@property (nonatomic, assign) BOOL useCameraPlus;

- (id)initWithImageSourceType:(QuickPostImageSourceType)imageSourceType useCameraPlus:(BOOL)useCameraPlus;

@end
