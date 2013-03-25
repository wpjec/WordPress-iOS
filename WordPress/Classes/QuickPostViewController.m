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

typedef enum {
    kAnimationDirectionUnknown = 0,
    kAnimationDirectionSlideLeft,
    kAnimationDirectionSlideRight,
    kAnimationDirectionSlideUp,
    kAnimationDirectionSlideDown
} AnimationDirection;

@interface QuickPostViewController () {
    WordPressAppDelegate *appDelegate;
    CGRect bodyTextFieldFrame;
    CGRect titleTextFieldFrame;
    UIView *visibleContainerSubView;
}

@property (nonatomic, strong) IBOutlet UIButton *choosePhotoButton;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIButton *detailsButton;
@property (nonatomic, strong) IBOutlet UITableView *detailsTableView;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UIView *photoSelectionMethodView;
@property (nonatomic, strong) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, strong) IBOutlet UITextField *titleTextField;

- (IBAction)choosePhotoButtonTapped:(id)sender;
- (IBAction)detailsButtonTapped:(id)sender;

- (void)animateKeyboardForNotification:(NSNotification *)notification showing:(BOOL)showing;
- (void)cancel;
- (void)checkPostButtonStatus;
- (void)dismiss;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (CGRect)offsetFrame:(CGRect)frame forAnimationDirection:(AnimationDirection)animationDirection reverse:(BOOL)reverse;
- (void)post;
- (Blog *)selectedBlog;
- (void)swapContainerViewContentTo:(UIView *)toView becomeResponder:(BOOL)becomeResponder;

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
    visibleContainerSubView = self.bodyTextView;
    bodyTextFieldFrame = self.bodyTextView.frame;
    [self.bodyTextView becomeFirstResponder];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
    UIView *toView = (visibleContainerSubView == self.photoSelectionMethodView ? self.bodyTextView : self.photoSelectionMethodView);
    [self swapContainerViewContentTo:toView becomeResponder:YES];
}

- (IBAction)detailsButtonTapped:(id)sender {
    UIView *toView = (visibleContainerSubView == self.detailsTableView ? self.bodyTextView : self.detailsTableView);
    [self swapContainerViewContentTo:toView becomeResponder:YES];
}

- (void)checkPostButtonStatus {
    self.navigationItem.rightBarButtonItem.enabled = self.bodyTextView.text || self.titleTextField.text;
}

- (CGRect)offsetFrame:(CGRect)frame forAnimationDirection:(AnimationDirection)animationDirection reverse:(BOOL)reverse {
    switch (animationDirection) {
        case kAnimationDirectionSlideDown :
            frame.origin.y = (reverse ? frame.size.height : -frame.size.height);
            break;
        case kAnimationDirectionSlideLeft :
            frame.origin.x = (reverse  ? -frame.size.width : frame.size.width);
            break;
        case kAnimationDirectionSlideRight :
            frame.origin.x = (reverse ? frame.size.width : -frame.size.width);
            break;
        case kAnimationDirectionSlideUp :
            frame.origin.y = (reverse ? -frame.size.height : frame.size.height);
            break;
        default :
            break;
    }

    return frame;
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

- (void)swapContainerViewContentTo:(UIView *)toView becomeResponder:(BOOL)becomeResponder {
    UIView *fromView = visibleContainerSubView;
    if (fromView == toView) {
        return;
    }

    AnimationDirection animationDirection;

    if (fromView == self.photoSelectionMethodView) {
        if (toView == self.detailsTableView) {
            animationDirection = kAnimationDirectionSlideLeft;
        } else if (toView == self.bodyTextView) {
            animationDirection = kAnimationDirectionSlideUp;
        }
    } else if (fromView == self.detailsTableView) {
        if (toView == self.photoSelectionMethodView) {
            animationDirection = kAnimationDirectionSlideRight;
        } else if (toView == self.bodyTextView) {
            animationDirection = kAnimationDirectionSlideUp;
        }
    } else if (fromView == self.bodyTextView) {
        animationDirection = kAnimationDirectionSlideDown;
    }

    [fromView resignFirstResponder];

    [self.containerView addSubview:toView];
    toView.frame = [self offsetFrame:self.containerView.bounds forAnimationDirection:animationDirection reverse:NO];

    [UIView transitionWithView:self.containerView duration:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        // NOTE: there's actually an animation glitch if fromView was the body text view
        //  because we're simultaneously animating the keyboard dismissal and the view transition.
        //  However, because the background of the text view matches that of the container view, the glitch
        //  is not noticeable. We could fix this by delaying this animation until the keyboard is done animating
        //  but since there's no impact, I think it's preferable to not induce that extra delay
        fromView.frame = [self offsetFrame:fromView.frame forAnimationDirection:animationDirection reverse:YES];
        toView.frame = self.containerView.bounds;
    } completion:^(BOOL finished) {
        fromView.frame = self.containerView.bounds;
        [fromView removeFromSuperview];
        visibleContainerSubView = toView;
        if (becomeResponder) {
            [toView becomeFirstResponder];
        }
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

#pragma mark - Keyboard management

- (void)keyboardWillShow:(NSNotification *)notification {
    [self animateKeyboardForNotification:notification showing:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self animateKeyboardForNotification:notification showing:NO];
}

- (void)animateKeyboardForNotification:(NSNotification *)notification showing:(BOOL)showing {
    NSDictionary *keyboardInfo = [notification userInfo];

    NSTimeInterval duration;
    UIViewAnimationCurve curve;

    [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];

    CGRect originalKeyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil] fromView:nil];

    CGRect frame;
    if (showing) {
        frame = self.bodyTextView.frame;
        CGRect convertedBodyFrame = [self.view convertRect:self.bodyTextView.frame fromView:self.containerView];
        frame.size.height = keyboardFrame.origin.y - convertedBodyFrame.origin.y;
    } else {
        // restore the original frame
        frame = bodyTextFieldFrame;
    }

    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:curve];
        self.bodyTextView.frame = frame;
    }];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField != self.titleTextField) {
        return;
    }

    [self swapContainerViewContentTo:self.bodyTextView becomeResponder:NO];

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
