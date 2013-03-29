//
//  QuickPostViewController.m
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "QuickPostViewController.h"
#import "Blog.h"
#import "CameraPlusPickerManager.h"
#import "Post.h"
#import "QuickPicturePreviewView.h"
#import "SidebarViewController.h"
#import "UIImageView+Gravatar.h"
#import "UIView+Entice.h"
#import "WordPressAppDelegate.h"
#import "WPPopoverBackgroundView.h"

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
    BOOL isDragged;
    BOOL isDragging;
    BOOL isFirstView;
    CGPoint dragStart;
    Post *post;
    CGRect titleTextFieldFrame;
    UIView *visibleContainerSubView;
}

@property (nonatomic, strong) IBOutlet BlogSelectorButton *blogSelector;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UIButton *detailsButton;
@property (nonatomic, strong) IBOutlet UIView *detailsView;
@property (nonatomic, strong) IBOutlet UIView *overflowView;
@property (nonatomic, strong) IBOutlet UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) IBOutlet QuickPicturePreviewView *photoPreview;
@property (nonatomic, strong) IBOutlet UIPopoverController *popController;
@property (nonatomic, strong) IBOutlet UITextField *tagsTextField;
@property (nonatomic, strong) IBOutlet UITextField *titleTextField;
@property (nonatomic, strong) IBOutlet UIView *titleView;

- (IBAction)detailsButtonSwiped:(UIPanGestureRecognizer *)gesture;
- (IBAction)detailsButtonTapped:(id)sender;

- (void)animateKeyboardForNotification:(NSNotification *)notification showing:(BOOL)showing;
- (void)cancel;
- (void)checkPostButtonStatus;
- (void)dismiss;
- (void)handleCameraPlusImages:(NSNotification *)notification;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)post;
- (void)showPhotoPicker:(UIImagePickerControllerSourceType)sourceType;

@end

@implementation QuickPostViewController

- (id)initWithPostType:(QuickPostType)postType imageSourceType:(UIImagePickerControllerSourceType)imageSourceType useCameraPlus:(BOOL)useCameraPlus {
    self = [super initWithNibName:@"QuickPostViewController" bundle:nil];
    if (self) {
        self.postType = postType;
        self.imageSourceType = imageSourceType;
        self.useCameraPlus = useCameraPlus;
    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.postType = QuickPostTypeText;
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

    bodyTextFieldFrame = self.bodyTextView.frame;

    self.blogSelector.delegate = self;
    [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];

    isFirstView = YES;

    if (self.postType == QuickPostTypeText) {
        self.photoPreview.hidden = YES;
    } else {
        CGRect frame = self.bodyTextView.frame;
        frame.size.width = (self.view.frame.size.width - self.photoPreview.frame.size.width);
        self.bodyTextView.frame = frame;
    }

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCameraPlusImages:) name:kCameraPlusImagesNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    if (isFirstView) {
        isFirstView = NO;
        switch (self.postType) {
            case QuickPostTypePhoto :
                [self showPhotoPicker:self.imageSourceType];
                break;
            case QuickPostTypeText :
            default:
                [self.bodyTextView becomeFirstResponder];
                self.placeholderLabel.center = self.bodyTextView.center;
                [self.placeholderLabel entice];
                break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super didReceiveMemoryWarning];
}

#pragma mark - Implementation

- (void)finishDragInDirection:(UISwipeGestureRecognizerDirection)direction {
    CGFloat finalY = (direction == UISwipeGestureRecognizerDirectionDown ? 0 : -self.detailsView.frame.size.height);

    [UIView animateWithDuration:0.1f animations:^{
        CGRect frame = self.overflowView.frame;
        frame.origin.y = finalY;
        self.overflowView.frame = frame;
    } completion:^(BOOL finished) {
        isDragging = NO;
        isDragged = (direction == UISwipeGestureRecognizerDirectionDown);
        self.panGesture.enabled = YES;
    }];
}

- (IBAction)detailsButtonSwiped:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateCancelled) {
        isDragging = NO;
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        dragStart = self.overflowView.center;
        isDragging = YES;
    }

    CGPoint translatedPoint = [gesture translationInView:self.overflowView];
    translatedPoint = CGPointMake(dragStart.x, dragStart.y + translatedPoint.y);
    self.overflowView.center = translatedPoint;

    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint relativePoint = [gesture locationInView:self.view];
        CGFloat threshold = 80.0f;

        UISwipeGestureRecognizerDirection direction;
        if (relativePoint.y <= threshold) {
            direction = UISwipeGestureRecognizerDirectionUp;
        } else if (relativePoint.y >= (self.detailsView.frame.size.height - threshold)) {
            direction = UISwipeGestureRecognizerDirectionDown;
        } else {
            direction = (self.overflowView.center.y > dragStart.y ? UISwipeGestureRecognizerDirectionDown : UISwipeGestureRecognizerDirectionUp);
        }

        [self finishDragInDirection:direction];
    }
}

- (IBAction)detailsButtonTapped:(id)sender {
    if (isDragging || isDragged) {
        return;
    }

    [self.view bounce:-40.0f];
}

- (void)checkPostButtonStatus {
    self.navigationItem.rightBarButtonItem.enabled = self.bodyTextView.text || self.titleTextField.text;
}

- (void)handleCameraPlusImages:(NSNotification *)notification {
    self.photo = [notification.userInfo objectForKey:@"image"];
}

- (void)saveImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (self.imageSourceType == UIImagePickerControllerSourceTypeCamera) {
            UIImageWriteToSavedPhotosAlbum(self.photo, nil, nil, nil);
        }

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            Media *media = nil;

            Blog *blog = self.blogSelector.activeBlog;
            if (!post) {
                post = [Post newDraftForBlog:blog];
            }

            if (post.media && [post.media count] > 0) {
                media = [post.media anyObject];
            } else {
                media = [Media newMediaForPost:post];
                int resizePreference = 0;
                if([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"]) {
                    resizePreference = [[[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] intValue];
                }

                MediaResize newSize = kResizeLarge;
                switch (resizePreference) {
                    case 1:
                        newSize = kResizeSmall;
                        break;
                    case 2:
                        newSize = kResizeMedium;
                        break;
                    case 4:
                        newSize = kResizeOriginal;
                        break;
                }

                [media setImage:self.photo withSize:newSize];
            }

            [media save];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        });
    });
}

- (void)showPhotoPicker:(UIImagePickerControllerSourceType)sourceType {
    if (self.useCameraPlus) {
        CameraPlusPickerManager *picker = [CameraPlusPickerManager sharedManager];
        picker.callbackURLProtocol = @"wordpress";
        picker.maxImages = 1;
        picker.imageSize = 4096;
        CameraPlusPickerMode mode = (sourceType == UIImagePickerControllerSourceTypeCamera) ? CameraPlusPickerModeShootOnly : CameraPlusPickerModeLightboxOnly;
        [picker openCameraPlusPickerWithMode:mode];
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = sourceType;
        picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        picker.allowsEditing = NO;
        picker.delegate = self;

        if (IS_IPAD) {
            self.popController = [[UIPopoverController alloc] initWithContentViewController:picker];
            if ([self.popController respondsToSelector:@selector(popoverBackgroundViewClass)]) {
                self.popController.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
            }
            self.popController.delegate = self;
            CGRect rect = CGRectMake((self.view.frame.size.width/2), 1.0f, 1.0f, 1.0f); // puts the arrow in the middle of the screen
            [self.popController presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentModalViewController:picker animated:YES];
        }
    }
}

#pragma mark - Nav Button Methods

- (void) cancel {
    self.photo = nil;
    if (post != nil) {
        [post deletePostWithSuccess:nil failure:nil];
    }
    [self dismiss];
}

- (void)dismiss {
    [self.sidebarViewController dismissModalViewControllerAnimated:YES];
}

- (void)post {
    Media *media = nil;
    Blog *blog = self.blogSelector.activeBlog;
    BOOL isImagePost = (self.postType != QuickPostTypeText);

    if (!post) {
        post = [Post newDraftForBlog:blog];
    } else {
        post.blog = blog;
        if (isImagePost) {
            media = [post.media anyObject];
            [media setBlog:blog];
        }
    }

    post.postTitle = self.titleTextField.text;
    post.content = self.bodyTextView.text;
    post.tags = self.tagsTextField.text;

    if (self.postType == QuickPostTypeText) {
        post.specialType = @"QuickPost";
    } else {
        post.postFormat = @"image";
        if (self.useCameraPlus) {
            post.specialType = @"QuickPhotoCameraPlus";
        } else {
            post.specialType = @"QuickPhoto";
        }
    }

    if (appDelegate.connectionAvailable == YES ) {
        if ([post.postFormat isEqualToString:@"image"]) {
            [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:media];
            [[NSNotificationCenter defaultCenter] addObserver:post selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:media];
        }

        appDelegate.isUploadingPost = YES;

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (isImagePost) {
                [media uploadWithSuccess:nil failure:nil];
                [post save];
            } else {
                [post uploadWithSuccess:nil failure:nil];
            }
        });

        [self dismiss];
        [self.sidebarViewController uploadQuickPost:post];
    } else {
        if (isImagePost) {
            [media setRemoteStatus:MediaRemoteStatusFailed];
        }

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
        CGRect convertedBodyFrame = [self.view convertRect:self.bodyTextView.frame fromView:self.overflowView];
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

    titleTextFieldFrame = self.titleTextField.frame;

    CGRect frame = self.titleTextField.frame;
    CGFloat width = (self.view.bounds.size.width - (2 * frame.origin.x));
    frame.size.width = width;

    [UIView animateWithDuration:0.3f animations:^{
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

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.bodyTextView becomeFirstResponder];
        return;
    }

    [self showPhotoPicker:(buttonIndex == 0 ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeCamera)];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    [self.titleTextField resignFirstResponder];
    [self.bodyTextView resignFirstResponder];
}

#pragma mark - BlogSelectorButtonDelegate methods

- (UIView *)blogSelectorButtonContainerView {
    return self.overflowView;
}

- (void)blogSelectorButtonWillBecomeActive:(BlogSelectorButton *)button {
    [self.titleTextField resignFirstResponder];
    [self.bodyTextView resignFirstResponder];
}

#pragma mark - UIPickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (self.popController) {
        [self.popController dismissPopoverAnimated:YES];
        self.popController = nil;
    }

    self.photo = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    self.photoPreview.image = self.photo;

    if (![self isViewLoaded]) {
        // If we get a memory warning on the way here our view could have unloaded.
        // In order to prevent a crash we'll make sure its loaded before
        // dismissing the modal.
        [self view];
        [self.blogSelector loadBlogsForType:BlogSelectorButtonTypeQuickPhoto];
        self.blogSelector.delegate = self;
    }

    [picker dismissModalViewControllerAnimated:NO];
    [self saveImage];

    [self.bodyTextView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.f];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    picker.delegate = nil;
    [self dismiss];
}

#pragma mark - Quick Photo preview view delegate

- (void)pictureWillZoom {
    [self.titleTextField resignFirstResponder];
    [self.bodyTextView resignFirstResponder];
    [self.view bringSubviewToFront:self.photoPreview];
}

- (void)pictureWillRestore {
    [self.bodyTextView becomeFirstResponder];
}

#pragma mark - UIPopoverViewController Delegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self dismiss];
}

@end
