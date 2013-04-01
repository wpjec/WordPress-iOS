//
//  BlogSelectorButton.m
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "BlogSelectorButton.h"
#import "WordPressAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"

@interface BlogSelectorButton ()

@property (nonatomic, readwrite, assign) NSUInteger blogCount;

- (void)tap;
- (void)deviceDidRotate:(NSNotification *)notification;

@end

@implementation BlogSelectorButton

@synthesize activeBlog;
@synthesize delegate;

- (void)dealloc
{
    self.activeBlog = nil;
     blavatarImageView = nil;
     postToLabel = nil;
     blogTitleLabel = nil;
     selectorImageView = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        active = NO;
        self.autoresizesSubviews = YES;
        postToLabel = [[UILabel alloc] init];
        blavatarImageView = [[UIImageView alloc] init];
        blogTitleLabel = [[UILabel alloc] init];
        selectorImageView = [[UIImageView alloc] init];

        [self addSubview:postToLabel];
        [self addSubview:blavatarImageView];
        [self addSubview:blogTitleLabel];
        [self addSubview:selectorImageView];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }

    return self;
}

- (void)layoutSubviews {
    static const CGFloat padding = 5.0f;

    NSString *postToLabelText = (self.blogCount == 1 ? NSLocalizedString(@"Posting to:", @"") : NSLocalizedString(@"Post to:", @""));

    postToLabel.font = [UIFont systemFontOfSize:17.0f];
    postToLabel.textColor = [UIColor blackColor];
    postToLabel.text = postToLabelText;

    CGRect postToFrame = self.bounds;
    postToFrame.origin.x = (padding * 2);
    postToFrame.size.width = [postToLabel.text sizeWithFont:postToLabel.font].width + padding;
    if (active) {
        postToFrame.size.height = normalFrame.size.height;
    }
    postToLabel.frame = postToFrame;

    CGRect blavatarFrame = CGRectMake(postToFrame.origin.x + postToFrame.size.width, 3.0f, 36.0f, 36.0f);
    blavatarImageView.frame = blavatarFrame;
    blavatarImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

    CGRect selectorImageFrame = self.bounds;
    selectorImageFrame.size.width = 15.0f;
    selectorImageFrame.origin.x = self.bounds.size.width - selectorImageFrame.size.width - (padding * 2);
    if (active) {
        selectorImageFrame.size.height = normalFrame.size.height;
    }

    CGRect blogTitleFrame = self.bounds;
    blogTitleFrame.origin.x = blavatarFrame.origin.x + blavatarFrame.size.width + padding;
    blogTitleFrame.size.width -= (postToFrame.size.width + blavatarFrame.size.width + selectorImageFrame.size.width) + (padding * 6);
    if (active) {
        blogTitleFrame.size.height = normalFrame.size.height;
    }

    blogTitleLabel.frame = blogTitleFrame;
    blogTitleLabel.font = [UIFont systemFontOfSize:17];
    blogTitleLabel.numberOfLines = 1;
    blogTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    selectorImageView.frame = selectorImageFrame;
    selectorImageView.contentMode = UIViewContentModeCenter;
    selectorImageView.image = [UIImage imageNamed:@"downArrow"];
    selectorImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

    if (![[self actionsForTarget:self forControlEvent:UIControlEventAllEditingEvents] count]) {
        [self addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)deviceDidRotate:(NSNotification *)notification {
    if (active && IS_IPHONE) {
        normalFrame.size.width = self.frame.size.width;
    }
}

#pragma mark -
#pragma mark Custom methods

- (NSString *)defaultsKey {
    switch (blogType) {
        case BlogSelectorButtonTypeQuickPhoto:
            return kBlogSelectorQuickPhoto;
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)loadBlogsForType:(BlogSelectorButtonType)aType {
    blogType = aType;

    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    NSPersistentStoreCoordinator *psc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] persistentStoreCoordinator];
    NSError *error = nil;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    sortDescriptor = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];

    self.blogCount = [results count];

    NSString *defaultsKey = [self defaultsKey];
    if (defaultsKey != nil) {
        NSString *blogId = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
        if (blogId != nil) {
            @try {
                self.activeBlog = (Blog *)[moc existingObjectWithID:[psc managedObjectIDForURIRepresentation:[NSURL URLWithString:blogId]] error:nil];
            }
            @catch (NSException *exception) {
                self.activeBlog = nil;
            }
            if (!self.activeBlog) {
                // The default blog was invalid, remove the stored default
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
            }
        }
    }

    if ([results count] > 0 && !self.activeBlog) {
        self.activeBlog = [results objectAtIndex:0];
    }
}

- (void)setBlogCount:(NSUInteger)blogCount {
    if (_blogCount != blogCount) {
        _blogCount = blogCount;

        if (_blogCount > 1) {
            selectorImageView.alpha = 1.0f;
            self.enabled = YES;
        } else {
            // Disable selecting a blog if user has only one blog in the app.
            selectorImageView.alpha = 0.0f;
            self.enabled = NO;
        }

        [self setNeedsLayout];
    }
}

- (void)setActiveBlog:(Blog *)aBlog {
    if (aBlog != activeBlog) {
        activeBlog = aBlog;
        [blavatarImageView setImageWithBlavatarUrl:activeBlog.blavatarUrl isWPcom:activeBlog.isWPcom];
        blogTitleLabel.text = activeBlog.blogName;
        if ([blogTitleLabel.text isEmpty]) {
            blogTitleLabel.text = activeBlog.hostURL;
        }
    }
}

- (void)tap {
    WPFLogMethod();
    active = !active;
    
    if (self.delegate) {
        if (active) {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonWillBecomeActive:)]) {
                [self.delegate blogSelectorButtonWillBecomeActive:self];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonWillBecomeInactive:)]) {
                [self.delegate blogSelectorButtonWillBecomeInactive:self];
            }            
        }
    }
    
    UIView *container;
    if ([self.delegate respondsToSelector:@selector(blogSelectorButtonContainerView)]) {
        container = [self.delegate blogSelectorButtonContainerView];
    } else {
        container = self;
    }

    if (active) {
        normalFrame = self.frame;

        CGRect selectionViewFrame = container.superview.bounds;
        selectionViewFrame.origin.y += self.frame.origin.y + self.frame.size.height;
        selectionViewFrame.size.height -= self.frame.size.height;
        if (!selectorViewController) {
            selectorViewController = [[BlogSelectorViewController alloc] initWithStyle:UITableViewStylePlain];
            selectorViewController.selectedBlog = self.activeBlog;
            selectorViewController.delegate = self;
        }
        selectorViewController.view.frame = selectionViewFrame;
        [container addSubview:selectorViewController.view];
        selectorViewController.view.alpha = 0.0f;
    }

    [UIView animateWithDuration:0.15f animations:^{
        if (active) {
            CGRect frame = selectorViewController.view.frame;
            frame.origin.y = self.frame.size.height;
            selectorViewController.view.frame = frame;
            selectorViewController.view.alpha = 1.0f;

            self.frame = container.superview.bounds;
            selectorImageView.transform = CGAffineTransformMakeRotation(M_PI);
        } else {
            self.frame = normalFrame;
            selectorImageView.transform = CGAffineTransformMakeRotation(0);

            CGRect frame = selectorViewController.view.frame;
            frame.origin.y = self.frame.origin.y + self.frame.size.height;
            selectorViewController.view.frame = frame;
            selectorViewController.view.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        if (!active) {
            [selectorViewController.view removeFromSuperview];
        }
    }];
    
    if (self.delegate) {
        if (active) {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonDidBecomeActive:)]) {
                [self.delegate blogSelectorButtonDidBecomeActive:self];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(blogSelectorButtonDidBecomeInactive:)]) {
                [self.delegate blogSelectorButtonDidBecomeInactive:self];
            }            
        }
    }
}

#pragma mark - Blog Selector delegate

- (void)blogSelectorViewController:(BlogSelectorViewController *)blogSelector didSelectBlog:(Blog *)blog {
    if ([self.delegate respondsToSelector:@selector(blogSelectorButton:didSelectBlog:)]) {
        [self.delegate blogSelectorButton:self didSelectBlog:blog];
    }

    self.activeBlog = blog;
    NSString *defaultsKey = [self defaultsKey];
    if (defaultsKey != nil) {
        NSString *objectID = [[[self.activeBlog objectID] URIRepresentation] absoluteString];
        [[NSUserDefaults standardUserDefaults] setObject:objectID forKey:defaultsKey];
    }
    [self tap];
}

@end
