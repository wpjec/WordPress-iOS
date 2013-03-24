//
//  QuickPostViewController.m
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "QuickPostViewController.h"
#import "Blog.h"
#import "Post.h"
#import "SidebarViewController.h"
#import "UIView+Entice.h"
#import "WordPressAppDelegate.h"

@interface QuickPostViewController () {
    WordPressAppDelegate *appDelegate;
    UIView *visibleContainerView;
    CGRect titleTextFieldFrame;
}

- (void)cancel;
- (void)checkPostButtonStatus;
- (void)dismiss;
- (void)post;
- (Blog *)selectedBlog;
- (void)swapContainerViewContentTo:(UIView *)toView;

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

    appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];

    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Post", @"") style:UIBarButtonItemStyleDone target:self action:@selector(post)];

    [postButton setEnabled:NO];
    self.navigationItem.rightBarButtonItem = postButton;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];

    self.placeholderLabel.text = NSLocalizedString(@"Tap here to begin writing", @"Placeholder for the main body text. Should hint at tapping to enter text (not specifying body text).");

    [self.view sendSubviewToBack:self.containerView];
    visibleContainerView = self.bodyTextView;
}

- (void)viewWillAppear:(BOOL)animated {
    self.placeholderLabel.center = self.bodyTextView.center;

    [self.placeholderLabel entice];
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

#pragma mark - Implementation

- (IBAction)choosePhotoButtonTapped:(id)sender {
    [self swapContainerViewContentTo:(visibleContainerView == self.photoSelectionMethodView ? self.bodyTextView : self.photoSelectionMethodView)];
}

- (IBAction)detailsButtonTapped:(id)sender {
    [self swapContainerViewContentTo:(visibleContainerView == self.detailsTableView ? self.bodyTextView : self.detailsTableView)];
}

- (void)checkPostButtonStatus {
    self.navigationItem.rightBarButtonItem.enabled = self.bodyTextView.text || self.titleTextField.text;
}

/**
 * Trivial implementation for now, just returns the first blog, once blog selection is implemented this will change
 */
- (Blog *)selectedBlog {
    NSManagedObjectContext *moc = [appDelegate managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];

    return [results objectAtIndex:0];
}

- (void)swapContainerViewContentTo:(UIView *)toView {
    UIView *fromView = visibleContainerView;

    [fromView resignFirstResponder];

    [self.containerView addSubview:toView];
    CGRect frame = self.containerView.bounds;
    frame.origin.y -= frame.size.height;
    toView.frame = frame;

    [UIView transitionWithView:self.containerView duration:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = fromView.frame;
        frame.origin.y = self.containerView.frame.size.height;

        fromView.frame = frame;
        toView.frame = self.containerView.bounds;
    } completion:^(BOOL finished) {
        [fromView removeFromSuperview];
        visibleContainerView = toView;
    }];
}

#pragma mark - Nav Button Methods

- (void) cancel {
    [self dismiss];
}

- (void)dismiss {
    [self.sidebarViewController dismissModalViewControllerAnimated:YES];
}

- (void) post {
    Blog *blog = [self selectedBlog];
    Post *post = [Post newDraftForBlog:blog];

    post.postTitle = self.titleTextField.text;
    post.content = self.bodyTextView.text;

    if (appDelegate.connectionAvailable) {
        appDelegate.isUploadingPost = YES;

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [post uploadWithSuccess:nil failure:nil];
        });

        [self dismiss];
        // TODO: remove vestiges of QuickPhoto from sidebar view controller, change this to uploadQuickPost
        [self.sidebarViewController uploadQuickPhoto:post];
    } else {
        [post save];
        [self dismiss];

        NSString *title = NSLocalizedString(@"Quick Post Failed", @"");
        NSString *message = NSLocalizedString(@"The Internet connection appears to be offline. The post has been saved as a local draft, you can publish it later.", @"");
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"");

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];

        [alertView show];
    }
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField != self.titleTextField) {
        return;
    }

    [self swapContainerViewContentTo:self.bodyTextView];

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

    [self checkPostButtonStatus];

    [UIView animateWithDuration:0.3f animations:^{
        // TODO: This animation is wonky, need to investigate why
        self.titleTextField.frame = titleTextFieldFrame;

        self.choosePhotoButton.alpha = 1.0f;
        self.detailsButton.alpha = 1.0f;
    }];
}

#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView {
    if (textView != self.bodyTextView) {
        return;
    }

    [self checkPostButtonStatus];
}

#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyCell"];
    cell.textLabel.text = [NSString stringWithFormat:@"Cell #%d", indexPath.row];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

#pragma mark - UITableViewDelegate methods

@end
