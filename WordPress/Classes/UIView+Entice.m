//
//  UIView+Entice.m
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UIView+Entice.h"

@implementation UIView (Entice)

- (void)entice {
    self.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
    [UIView animateWithDuration:0.5f animations:^{
        [UIView setAnimationRepeatCount:1.0f];
        self.transform = CGAffineTransformIdentity;
    }];
}

@end
