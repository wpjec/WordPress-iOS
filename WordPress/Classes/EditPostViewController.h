#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "WPKeyboardToolbar.h"
#import "WPCategorySelectionTableViewController.h"

#define kSelectionsCategoriesContext ((void *)2000)

@class AbstractPost;

typedef NS_ENUM(NSUInteger, EditPostViewControllerMode) {
	EditPostViewControllerModeNewPost,
	EditPostViewControllerModeEditPost
};

@interface EditPostViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate, UITextViewDelegate, UIPopoverControllerDelegate,WPKeyboardToolbarDelegate, WPCategorySelectionTableViewControllerDelegate>
- (id)initWithPost:(AbstractPost *)aPost;
@end
