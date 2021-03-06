//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import "UICollectionView+Draggable.h"
#import "LSCollectionViewHelper.h"
#import "ProjectDetailViewController.h"
#import <objc/runtime.h>

@implementation UICollectionView (Draggable)

- (LSCollectionViewHelper *)getHelper
{
    LSCollectionViewHelper *helper = objc_getAssociatedObject(self, "LSCollectionViewHelper");
    if(helper == nil) {
        helper = [[LSCollectionViewHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, "LSCollectionViewHelper", helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

- (BOOL)draggable
{
    return [self getHelper].enabled;
}

- (void)setDraggable:(BOOL)draggable
{
    [self getHelper].enabled = draggable;
}

- (UIEdgeInsets)scrollingEdgeInsets
{
    return [self getHelper].scrollingEdgeInsets;
}

- (void)setScrollingEdgeInsets:(UIEdgeInsets)scrollingEdgeInsets
{
    [self getHelper].scrollingEdgeInsets = scrollingEdgeInsets;
}

- (CGFloat)scrollingSpeed
{
    return [self getHelper].scrollingSpeed;
}

- (void)setScrollingSpeed:(CGFloat)scrollingSpeed
{
    [self getHelper].scrollingSpeed = scrollingSpeed;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {

    if (point.y < 90) return NO;
    else return YES;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    if ([projectVC.editProjectNameTextField isFirstResponder]) [projectVC.editProjectNameTextField resignFirstResponder];
}

@end
