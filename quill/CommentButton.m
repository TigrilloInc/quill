//
//  CommentButton.m
//  mailcore2
//
//  Created by Alex Costantini on 10/27/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "CommentButton.h"
#import "DrawView.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"

@implementation CommentButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userImage = [UIImage imageNamed:@"user.png"];
        [self setImage:self.userImage forState:UIControlStateNormal];
        
        self.commentImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"usercomment.png"]];
        self.commentImage.center = CGPointMake(110, 110);
        [self addSubview:self.commentImage];
        
        self.highlightedImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"usercommenthighlight.png"]];
        self.highlightedImage.center = CGPointMake(110, 110);
        self.highlightedImage.hidden = true;
        [self addSubview:self.highlightedImage];
        
        UIImage *deleteImage = [UIImage imageNamed:@"close.png"];
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton.frame = CGRectMake(-deleteImage.size.width/2, -deleteImage.size.height/2, deleteImage.size.width, deleteImage.size.height);
        [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
        self.deleteButton.transform = CGAffineTransformMakeScale(4, 4);
        [self.deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.deleteButton];
        [self bringSubviewToFront:self.deleteButton];
        self.deleteButton.hidden = true;
    }
    return self;
}

-(void) deleteTapped {
    
    DrawView *drawView = (DrawView *)self.superview;
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:drawView.boardID] objectForKey:@"commentsID"];
    NSString *commentThreadString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/", commentsID, self.commentThreadID];
    Firebase *commentThreadRef = [[Firebase alloc] initWithUrl:commentThreadString];
    [commentThreadRef removeValue];
    
    [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] removeObjectForKey:self.commentThreadID];
    
    UISplitViewController *splitVC = (UISplitViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[splitVC.viewControllers objectAtIndex:1];
    projectVC.activeCommentThreadID = nil;
    
    [self removeFromSuperview];
    
    [drawView hideChat];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    CGPoint pointForTargetView = [self.deleteButton convertPoint:point fromView:self];
    
    if (CGRectContainsPoint(self.deleteButton.bounds, pointForTargetView)) {
        
        return [self.deleteButton hitTest:pointForTargetView withEvent:event];
    }
    
    return [super hitTest:point withEvent:event];
}

@end
