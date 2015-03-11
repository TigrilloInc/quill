//
//  CommentButton.m
//  mailcore2
//
//  Created by Alex Costantini on 10/27/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import "CommentButton.h"
#import "BoardView.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"
#import "IdenticonView.h"
#import "NSString+MD5.h"

@implementation CommentButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.adjustsImageWhenHighlighted = NO;

        self.commentImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"usercomment3.png"]];
        self.commentImage.center = CGPointMake(125, 136);
        [self addSubview:self.commentImage];
        
        self.highlightedImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"usercommenthighlight4.png"]];
        self.highlightedImage.center = CGPointMake(125, 136);
        self.highlightedImage.hidden = true;
        [self addSubview:self.highlightedImage];
        
        UIImage *deleteImage = [UIImage imageNamed:@"close.png"];
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton.frame = CGRectMake(-deleteImage.size.width/2, -deleteImage.size.height/2, deleteImage.size.width, deleteImage.size.height);
        [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
        self.deleteButton.transform = CGAffineTransformMakeScale(.4, .4);
        [self.deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.deleteButton];
        [self bringSubviewToFront:self.deleteButton];
        self.deleteButton.hidden = true;
    }
    return self;
}

-(void) deleteTapped {
    
    BoardView *boardView = (BoardView *)self.superview;
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:boardView.boardID] objectForKey:@"commentsID"];
    NSString *commentThreadString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/", commentsID, self.commentThreadID];
    Firebase *commentThreadRef = [[Firebase alloc] initWithUrl:commentThreadString];
    [[commentThreadRef childByAppendingPath:@"info"] removeAllObservers];
    [[commentThreadRef childByAppendingPath:@"messages"] removeAllObservers];
    [[commentThreadRef childByAppendingPath:@"updatedAt"] removeAllObservers];
    [commentThreadRef removeValue];
    
    [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] removeObjectForKey:self.commentThreadID];
    
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    projectVC.activeCommentThreadID = nil;
    
    [self removeFromSuperview];
    
    if ([projectVC.chatTextField isFirstResponder]) [projectVC.chatTextField resignFirstResponder];
}

- (void) generateIdenticon {
    
    NSMutableArray *tileValues = [NSMutableArray array];
    
    for (int i = 0; i < 25; i++) [tileValues addObject:[NSNull null]];
    
    NSString *idString = [self.userID MD5];
    
    NSArray *tileColors = @[ [CIColor colorWithRed:(5.0/255.0) green:(66.0/255.0) blue:(76.0/255.0)],
                             [CIColor colorWithRed:(40.0/255.0) green:(97.0/255.0) blue:(117.0/255.0)],
                             [CIColor colorWithRed:(88.0/255.0) green:(176.0/255.0) blue:(207.0/255.0)],
                             [CIColor colorWithRed:(243.0/255.0) green:(92.0/255.0) blue:(86.0/255.0)],
                             [CIColor colorWithRed:(243.0/255.0) green:(133.0/255.0) blue:(93.0/255.0)],
                             [CIColor colorWithRed:(239.0/255.0) green:(193.0/255.0) blue:(97.0/255.0)],
                             ];
    int userImageNum = 0;
    CIColor *tileColor;
    
    
    for (int i=0; i<17; i++) {
        
        NSString *subString = [idString substringWithRange:NSMakeRange(i, 1)];
        
        NSInteger hexValue;
        
        if ([subString isEqualToString:@"a"]) hexValue = 10;
        else if ([subString isEqualToString:@"b"]) hexValue = 11;
        else if ([subString isEqualToString:@"c"]) hexValue = 12;
        else if ([subString isEqualToString:@"d"]) hexValue = 13;
        else if ([subString isEqualToString:@"e"]) hexValue = 14;
        else if ([subString isEqualToString:@"f"]) hexValue = 15;
        else hexValue = [subString integerValue];
        
        if (i==0) {
            [tileValues replaceObjectAtIndex:0 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:4 withObject:@(hexValue)];
        }
        if (i==1) {
            [tileValues replaceObjectAtIndex:1 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:3 withObject:@(hexValue)];
        }
        if (i==2) {
            [tileValues replaceObjectAtIndex:2 withObject:@(hexValue)];
        }
        if (i==3) {
            [tileValues replaceObjectAtIndex:5 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:9 withObject:@(hexValue)];
        }
        if (i==4) {
            [tileValues replaceObjectAtIndex:6 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:8 withObject:@(hexValue)];
        }
        if (i==5) {
            [tileValues replaceObjectAtIndex:7 withObject:@(hexValue)];
        }
        if (i==6) {
            [tileValues replaceObjectAtIndex:10 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:14 withObject:@(hexValue)];
        }
        if (i==7) {
            [tileValues replaceObjectAtIndex:11 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:13 withObject:@(hexValue)];
        }
        if (i==8) {
            [tileValues replaceObjectAtIndex:12 withObject:@(hexValue)];
        }
        if (i==9) {
            [tileValues replaceObjectAtIndex:15 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:19 withObject:@(hexValue)];
        }
        if (i==10) {
            [tileValues replaceObjectAtIndex:16 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:18 withObject:@(hexValue)];
        }
        if (i==11) {
            [tileValues replaceObjectAtIndex:17 withObject:@(hexValue)];
        }
        if (i==12) {
            [tileValues replaceObjectAtIndex:20 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:24 withObject:@(hexValue)];
        }
        if (i==13) {
            [tileValues replaceObjectAtIndex:21 withObject:@(hexValue)];
            [tileValues replaceObjectAtIndex:23 withObject:@(hexValue)];
        }
        if (i==14) {
            [tileValues replaceObjectAtIndex:22 withObject:@(hexValue)];
        }
        if (i==15) {
            userImageNum = hexValue%6;
            NSString *imageString = [NSString stringWithFormat:@"userbutton%i.png", userImageNum+1];
            self.userImage = [UIImage imageNamed:imageString];
            [self setImage:self.userImage forState:UIControlStateNormal];
        }
        if (i==16) {
            if (userImageNum == hexValue%6) {
                NSMutableArray *newTileColors = [tileColors mutableCopy];
                [newTileColors removeObjectAtIndex:userImageNum];
                tileColor = newTileColors[hexValue%5];
            }
            else tileColor = tileColors[hexValue%6];
        }
    }
    
    IdenticonView *identicon = [[IdenticonView alloc] initWithFrame:CGRectMake(0, 0, self.userImage.size.width/2, self.userImage.size.height/2)];
    identicon.tileValues = tileValues;
    identicon.tileColor = tileColor;
    [self addSubview:identicon];
    identicon.center = CGPointMake(125,115);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    CGPoint pointForTargetView = [self.deleteButton convertPoint:point fromView:self];
    
    if (CGRectContainsPoint(self.deleteButton.bounds, pointForTargetView)) {
        
        return [self.deleteButton hitTest:pointForTargetView withEvent:event];
    }
    
    return [super hitTest:point withEvent:event];
}

@end
