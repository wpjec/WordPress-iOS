//
//  QuickPostViewController.m
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "QuickPostViewController.h"
#import "FileLogger.h"
#import "SidebarViewController.h"
#import "UIView+Entice.h"

@interface QuickPostViewController () {
    CGRect titleTextFieldFrame;
}

- (void) cancel;
- (void) dismiss;
- (void) post;

@end

@implementation QuickPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Post", @"") style:UIBarButtonItemStyleDone target:self action:@selector(post)];

    [postButton setEnabled:NO];
    self.navigationItem.rightBarButtonItem = postButton;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    self.placeholderLabel.text = NSLocalizedString(@"Tap here to begin writing", @"Placeholder for the main body text. Should hint at tapping to enter text (not specifying body text).");
}

- (void)viewWillAppear:(BOOL)animated {
    self.placeholderLabel.center = self.bodyTextView.center;

    [self.placeholderLabel entice];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

#pragma mark - Nav Button Methods

- (void) cancel {
    [self dismiss];
}

- (void)dismiss {
    [self.sidebarViewController dismissModalViewControllerAnimated:YES];
}

- (void) post {
    [self dismiss];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField != self.titleTextField) {
        return;
    }

    titleTextFieldFrame = self.titleTextField.frame;

    CGRect frame = self.titleTextField.frame;
    CGFloat width = (self.view.bounds.size.width - (2 * frame.origin.x));
    frame.size.width = width;

    [UIView animateWithDuration:0.3f animations:^{
        self.choosePhotoButton.alpha = 0.0f;
        self.detailsButton.alpha = 0.0f;

        self.titleTextField.frame = frame;
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField != self.titleTextField) {
        return;
    }

    [UIView animateWithDuration:0.3f animations:^{
        // TODO: This animation is wonky, need to investigate why
        self.titleTextField.frame = titleTextFieldFrame;

        self.choosePhotoButton.alpha = 1.0f;
        self.detailsButton.alpha = 1.0f;
    }];
}

@end
