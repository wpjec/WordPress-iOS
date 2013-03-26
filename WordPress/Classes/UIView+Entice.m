//
//  UIView+Entice.m
//  WordPress
//
//  Created by Joshua Cohen on 3/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UIView+Entice.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Entice)

/*
 * Courtesy of http://danielsaidi.wordpress.com/2012/09/03/ios-bounce-animation/
 */
+ (CAKeyframeAnimation*)dockBounceAnimationWithViewHeight:(CGFloat)viewHeight
{
    NSUInteger const kNumFactors    = 22;
    CGFloat const kFactorsPerSec    = 30.0f;
    CGFloat const kFactorsMaxValue  = 128.0f;
    CGFloat factors[22]             = {0,  60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32, 0, 0, 18, 28, 32, 28, 18, 0};

    NSMutableArray* transforms = [NSMutableArray array];

    for(NSUInteger i = 0; i < kNumFactors; i++)
    {
        CGFloat positionOffset  = factors[i] / kFactorsMaxValue * viewHeight;
        CATransform3D transform = CATransform3DMakeTranslation(0.0f, -positionOffset, 0.0f);

        [transforms addObject:[NSValue valueWithCATransform3D:transform]];
    }

    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.repeatCount           = 1;
    animation.duration              = kNumFactors * 1.0f/kFactorsPerSec;
    animation.fillMode              = kCAFillModeForwards;
    animation.values                = transforms;
    animation.removedOnCompletion   = YES; // final stage is equal to starting stage
    animation.autoreverses          = NO;

    return animation;
}

- (void)bounce:(CGFloat)height {
    CAKeyframeAnimation* animation = [[self class] dockBounceAnimationWithViewHeight:height];
    [self.layer addAnimation:animation forKey:@"bouncing"];
}

- (void)entice {
    self.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
    [UIView animateWithDuration:0.5f animations:^{
        [UIView setAnimationRepeatCount:1.0f];
        self.transform = CGAffineTransformIdentity;
    }];
}

@end
