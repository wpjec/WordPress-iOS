//
//  WPCategorySelectionTableViewController.m
//  WordPress
//
//  Created by Joshua Cohen on 3/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPCategorySelectionTableViewController.h"
#import "CPopoverManager.h"
#import "Blog.h"
#import "WPAddCategoryViewController.h"
#import "WPPopoverBackgroundView.h"

#define kSelectionsCategoriesContext ((void *)2000)

@interface WPCategorySelectionTableViewController ()<UIPopoverControllerDelegate> {
    UIPopoverController *popover;
    CGRect popoverRect;
    UIView *popoverView;
}

@property (nonatomic, readonly) Blog *blog;

- (NSArray *)allCategories;
- (void)categoryCreated:(NSNotification *)notification;
- (void)populate;
- (NSArray *)selectedCategories;
- (void)showAddNewCategoryView:(id)sender;

@end

@implementation WPCategorySelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_add"] style:UIBarButtonItemStyleBordered target:self action:@selector(showAddNewCategoryView:)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryCreated:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void)didReceiveMemoryWarning {
    WPFLogMethod();
    [super didReceiveMemoryWarning];
}

- (void)deviceDidRotate:(NSNotification *)notification {
    if (popover) {
        // Redisplay the popover to ensure it's in the correct location after rotation
        [popover presentPopoverFromRect:popoverRect inView:popoverView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - Public Implementation

- (Blog *) blog {
    return [self.delegate blogForCategorySelection];
}

- (void)showInNavigationController:(UINavigationController *)navigationController {
    [self populate];

    [navigationController pushViewController:self animated:YES];
}

- (void)showInPopoverViewFromView:(UIView *)view rect:(CGRect)rect {
    [self populate];

    UINavigationController *navController;
    if (self.navigationController) {
        navController = self.navigationController;
    } else {
        navController = [[UINavigationController alloc] initWithRootViewController:self];
    }

    popoverView = view;
    popoverRect = rect;

    popover = [[UIPopoverController alloc] initWithContentViewController:navController];
    popover.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
    popover.delegate = self;

    [popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [[CPopoverManager instance] setCurrentPopoverController:popover];
}

#pragma mark - Private Implementation

- (NSArray *)allCategories {
    return [self.blog sortedCategories];
}

- (void)populate {
    [self populateDataSource:[self allCategories] havingContext:kSelectionsCategoriesContext selectedObjects:[self selectedCategories] selectionType:kCheckbox andDelegate:self];
}

- (NSArray *)selectedCategories {
    return [self.delegate selectedCategories];
}

#pragma mark - WPSelectionTableViewControllerDelegate methods

- (void)selectionTableViewController:(WPSelectionTableViewController *)selectionController completedSelectionsWithContext:(void *)context selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    WPFLogMethod();
    if (!isChanged) {
        return;
    }

    if (context == kSelectionsCategoriesContext) {
        [self.delegate categoriesSelected:selectedObjects];
    }
}

- (void)categoryCreated:(NSNotification *)notification {
    WPFLogMethod();
    if ([self curContext] == kSelectionsCategoriesContext) {
        [self populate];
    }
}

- (void)showAddNewCategoryView:(id)sender {
    WPFLogMethod();
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
    addCategoryViewController.blog = self.blog;

    if (IS_IPAD) {
        [self pushViewController:addCategoryViewController animated:YES];
    } else {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
        [self presentModalViewController:nc animated:YES];
    }
}

@end
