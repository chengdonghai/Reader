//
//  ReaderCustomDismissAnimaton.m
//  Reader
//
//  Created by chengdonghai on 15/6/17.
//
//

#import "ReaderCustomDismissAnimaton.h"

@implementation ReaderCustomDismissAnimaton


-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect startFrame = [transitionContext initialFrameForViewController:fromVC];
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    
    CGRect finalFrame = CGRectOffset(startFrame, -startFrame.size.width, 0);
    
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
   
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        fromVC.view.frame = finalFrame;
    } completion:^(BOOL finished) {
         [transitionContext completeTransition:YES];
    }];
}

@end
