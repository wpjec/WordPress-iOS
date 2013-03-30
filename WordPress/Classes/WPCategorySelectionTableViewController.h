//
//  WPCategorySelectionTableViewController.h
//  WordPress
//
//  Created by Joshua Cohen on 3/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPSegmentedSelectionTableViewController.h"

@class Blog;

@protocol WPCategorySelectionTableViewControllerDelegate

- (Blog *)blogForCategorySelection;
- (void)categoriesSelected:(NSArray *)categories;
- (NSArray *)selectedCategories;

@end

@interface WPCategorySelectionTableViewController : WPSegmentedSelectionTableViewController

@property (nonatomic, weak) id<WPCategorySelectionTableViewControllerDelegate> delegate;

- (void)showInNavigationController:(UINavigationController *)navigationController;
- (void)showInPopoverViewFromView:(UIView *)view rect:(CGRect)rect;

@end
