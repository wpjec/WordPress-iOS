//
//  QuickPostViewController.h
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SidebarViewController;

@interface QuickPostViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UIButton *choosePhotoButton;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIButton *detailsButton;
@property (nonatomic, strong) IBOutlet UITableView *detailsTableView;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UIView *photoSelectionMethodView;
@property (nonatomic, strong) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, weak) SidebarViewController *sidebarViewController;
@property (nonatomic, strong) IBOutlet UITextField *titleTextField;

- (IBAction)choosePhotoButtonTapped:(id)sender;
- (IBAction)detailsButtonTapped:(id)sender;

@end
