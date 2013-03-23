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

@interface QuickPostViewController ()

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

@end
