//
//  BoardView.m
//  Quill
//
//  Created by Alex Costantini on 7/2/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//


#import "BoardView.h"

#import <QuartzCore/QuartzCore.h>

#import "FirebaseHelper.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "ProjectDetailViewController.h"
#import "NSDate+ServerDate.h"
#import "AvatarButton.h"
#import "Flurry.h"

static const CGFloat kPointMinDistance = 2.0f;
static const CGFloat kPointMinDistanceSquared = kPointMinDistance * kPointMinDistance;

@interface BoardView ()
@property (nonatomic,assign) CGPoint currentPoint;
@property (nonatomic,assign) CGPoint previousPoint;
@property (nonatomic,assign) CGPoint previousPreviousPoint;

#pragma mark Private Helper function
CGPoint midPoint(CGPoint p1, CGPoint p2);
@end

@implementation BoardView {
@private
    
    ProjectDetailViewController *projectVC;
    UIImage *incrementalImage;
    NSMutableArray *paths;
    
}

#pragma mark UIView lifecycle methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.penType = 1;
        self.shapeType = 1;
        self.lineColorNumber = @1;
        _empty = YES;
        self.activeUserIDs = [NSMutableArray array];
        self.gradientButton = nil;
        self.loadingView = nil;
        self.hideComments = true;
        self.backgroundColor = [UIColor clearColor];
        
        self.fadeView = [[UIView alloc] initWithFrame:self.frame];
        self.fadeView.backgroundColor = [UIColor whiteColor];
        self.fadeView.alpha = .5f;
        self.fadeView.hidden = true;
        [self addSubview:self.fadeView];
        
        self.leaveCommentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.leaveCommentLabel.userInteractionEnabled = NO;
        self.leaveCommentLabel.font = [UIFont fontWithName:@"SourceSansPro-LightIt" size:60];
        self.leaveCommentLabel.textColor = [UIColor lightGrayColor];
        self.leaveCommentLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.leaveCommentLabel.textAlignment = NSTextAlignmentCenter;
        self.leaveCommentLabel.text = @"tap anywhere to add a label...";
        [self.leaveCommentLabel sizeToFit];
        self.leaveCommentLabel.center = CGPointMake(self.center.x-20, self.center.y);
        self.leaveCommentLabel.alpha = .75;
        self.leaveCommentLabel.hidden = true;
        [self addSubview:self.leaveCommentLabel];
        
        self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 100, 200, 40)];
        self.userLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
        self.userLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.userLabel.textAlignment = NSTextAlignmentCenter;
        self.userLabel.hidden = true;
        [self addSubview:self.userLabel];
        
        projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;;
        
        if (projectVC.userRole > 0) self.drawable = true;
        else self.drawable = false;

        self.selectedAvatarUserID = nil;
        self.drawingTimers = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void) layoutAvatars {
    
    for (AvatarButton *avatar in self.avatarButtons) [avatar removeFromSuperview];
    [self.avatarBackgroundImage removeFromSuperview];
    
    self.avatarButtons = [NSMutableArray array];
    
    NSMutableArray *unsortedUserIDs = [self.activeUserIDs mutableCopy];

    if ([projectVC.activeBoardID isEqualToString:self.boardID]) {
        
        NSDictionary *subpathsDict = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"];
        
        for (NSString *userID in subpathsDict.allKeys) {

            if (![unsortedUserIDs containsObject:userID] && ((NSDictionary *)[subpathsDict objectForKey:userID]).allKeys.count > 1) [unsortedUserIDs addObject:userID];
        }
    }
    
    NSArray *userIDs = [unsortedUserIDs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    if (userIDs.count > 0) {
        
        CGRect imageRect = CGRectMake(0, 0, 325+(userIDs.count-1)*(66*4), 280);
        CGImageRef imageRef = CGImageCreateWithImageInRect([[UIImage imageNamed:@"avatarbackground.png"] CGImage], imageRect);
        self.avatarBackgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:imageRef]];
        CGImageRelease(imageRef);
        CGAffineTransform bgtr = CGAffineTransformScale(self.avatarBackgroundImage.transform, .25, .25);
        bgtr = CGAffineTransformRotate(bgtr, -M_PI_2);
        self.avatarBackgroundImage.transform = bgtr;
        self.avatarBackgroundImage.frame = CGRectMake(18+projectVC.carouselOffset, self.avatarBackgroundImage.frame.size.width-70, self.avatarBackgroundImage.frame.size.width, self.avatarBackgroundImage.frame.size.height);
        self.avatarBackgroundImage.alpha = .25;
        [self addSubview:self.avatarBackgroundImage];
    }

    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *avatarImage = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"avatar"];
        
        CGAffineTransform tr;
        
        if ([avatarImage isKindOfClass:[UIImage class]]) {
            
            [avatar setImage:avatarImage forState:UIControlStateNormal];
            avatar.frame = CGRectMake(-11.5+projectVC.carouselOffset, 49+(i-1)*66, avatarImage.size.width, avatarImage.size.height);
            avatar.shadowImage.hidden = false;
            avatar.imageView.layer.cornerRadius = avatarImage.size.width/2;
            avatar.imageView.layer.masksToBounds = YES;

            if (avatar.imageView.frame.size.height == 64) {
                
                avatar.frame = CGRectMake(21+projectVC.carouselOffset, 80+(i-1)*66, avatarImage.size.width, avatarImage.size.height);
                avatar.shadowImage.frame = CGRectMake(-3, 0, 70, 70);
                avatar.drawingImage.transform = avatar.highlightedImage.transform = CGAffineTransformMakeScale(.145, .145);
                avatar.drawingImage.center = avatar.highlightedImage.center = CGPointMake(32,32);
                tr = CGAffineTransformScale(avatar.transform, .86, .86);
            }
            else {
                
                avatar.shadowImage.center = CGPointMake(64, 69);
                avatar.drawingImage.transform = avatar.highlightedImage.transform = CGAffineTransformMakeScale(.29, .29);
                avatar.drawingImage.center = avatar.highlightedImage.center = CGPointMake(64.1, 64.1);
                tr = CGAffineTransformScale(avatar.transform, .432, .432);
            }
        }
        else {
            [avatar generateIdenticonWithShadow:true];
            avatar.frame = CGRectMake(-70.5+projectVC.carouselOffset, -12+(i-1)*66, avatar.userImage.size.width, avatar.userImage.size.height);
            tr = CGAffineTransformScale(avatar.transform, .25, .25);
        }

        tr = CGAffineTransformRotate(tr, -M_PI_2);
        avatar.transform = tr;
        if (![self.activeUserIDs containsObject:avatar.userID]) avatar.alpha = 0.5;
        [self addSubview:avatar];
        [self.avatarButtons addObject:avatar];
    }
}

-(void) layoutComments {
    
    for (CommentButton *commentButton in self.commentButtons) [commentButton removeFromSuperview];
    
    self.commentButtons = [NSMutableArray array];
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"commentsID"];
    NSDictionary *commentDict = [[FirebaseHelper sharedHelper].comments objectForKey:commentsID];

    if (!commentDict) return;
    
    for (NSString *commentThreadID in commentDict.allKeys) {
        
        CommentButton *button = [CommentButton buttonWithType:UIButtonTypeCustom];
        button.commentThreadID = commentThreadID;
        float x = [[[[commentDict objectForKey:commentThreadID] objectForKey:@"location"] objectForKey:@"x"] floatValue];
        float y = [[[[commentDict objectForKey:commentThreadID] objectForKey:@"location"] objectForKey:@"y"] floatValue];
        button.point = CGPointMake(x, y);
        button.userID = [[commentDict objectForKey:commentThreadID] objectForKey:@"owner"];
        
        [button generateIdenticon];
        button.frame = CGRectMake(0, 0, button.userImage.size.width, button.userImage.size.height);
        button.center = CGPointMake(button.point.x-40, button.point.y+22);
        CGAffineTransform tr = CGAffineTransformScale(button.transform, .25, .25);
        tr = CGAffineTransformRotate(tr, -M_PI_2);
        button.transform = tr;
 
        UIImage *avatarImage = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:button.userID] objectForKey:@"avatar"];

        if ([avatarImage isKindOfClass:[UIImage class]]) {
            
            UIImageView *customAvatar = [[UIImageView alloc] initWithImage:avatarImage];
            customAvatar.frame = CGRectMake(15, 0, 225, 225);
            [button addSubview:customAvatar];
            [button sendSubviewToBack:customAvatar];
            customAvatar.layer.cornerRadius = 110;
            customAvatar.layer.masksToBounds = YES;
            
            button.imageView.hidden = true;
            button.identiconView.hidden = true;
        }
        
        if ([[projectVC.updatedElements objectForKey:@"comments"] containsObject:commentThreadID])
            [button.commentImage setImage:[UIImage imageNamed:@"usercomment4.png"]];
        
        if ([button.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(commentLongPress:)];
            longPress.minimumPressDuration = .2;
            [button addGestureRecognizer:longPress];
        }
        
        if ([commentThreadID isEqualToString:projectVC.activeCommentThreadID]) {
            
            button.commentImage.hidden = true;
            button.highlightedImage.hidden = false;
            if (projectVC.userRole > 0) button.deleteButton.hidden = false;
            
            [self updateCarouselOffsetWithPoint:button.point];
        }
        
        [self addSubview:button];
        [button updateLabel];
        [self.commentButtons addObject:button];
        
        if ([self.boardID isEqualToString:projectVC.activeBoardID]) [projectVC updateCommentCount];
    }
    
    [self bringSubviewToFront:[self viewWithTag:1]];
}

#pragma mark private Helper function

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

#pragma mark Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.drawable) return;
    
    NSArray *allTouches = [[event allTouches] allObjects];
    
    if (allTouches.count > 2) return;
    
    if (allTouches.count == 2 && !projectVC.erasing && projectVC.userRole > 0) {
        
        CGPoint touch1 = [allTouches[0] locationInView:self];
        CGPoint touch2 = [allTouches[1] locationInView:self];
        
        if (self.gridOn) self.shapeRect = CGRectMake((round(touch1.x/24))*24, (round(touch1.y/32))*32, (round((touch2.x-touch1.x)/24))*24, (round((touch2.y-touch1.y)/32))*32);
        else self.shapeRect = CGRectMake(touch1.x, touch1.y, touch2.x-touch1.x, touch2.y-touch1.y);
        
        [[FirebaseHelper sharedHelper]resetUndo];
        
        CGRect bufferRect = CGRectInset(self.shapeRect, MIN(-80, -1*fabs(self.shapeRect.size.width*.2)), MIN(-80,-1*fabs(self.shapeRect.size.height*.2)));
        
        [self setNeedsDisplayInRect:bufferRect];

        return;
    }
    
    UITouch *touch = allTouches[0];

    if (self.selectedAvatarUserID) {
        
        self.userLabel.text = nil;
        self.userLabel.hidden = true;
        
        for (AvatarButton *avtr in self.avatarButtons) avtr.highlightedImage.hidden = true;
        
        self.selectedAvatarUserID = nil;
        [projectVC drawBoard:self];
    }
    
    if ([projectVC.chatTextField isFirstResponder] || [[projectVC.view viewWithTag:104] isFirstResponder] || [projectVC.commentTitleTextField isFirstResponder]) return;
    
    if (self.commenting) {
        
        [self addCommentAtPoint:[touch locationInView:self]];
        self.fadeView.hidden = true;
        return;
    }
    
    if (projectVC.erasing) {
        
        projectVC.eraserCursor.hidden = false;
        projectVC.eraserCursor.center = [touch locationInView:projectVC.view];
    }
    
    if (projectVC.userRole > 0) [self addUserDrawing:[FirebaseHelper sharedHelper].uid];
    
    [projectVC.view viewWithTag:4].alpha = 1;
    [projectVC.view viewWithTag:3].alpha = .3;
    [projectVC.view viewWithTag:2].alpha = 1;
    
    // initializes our point records to current location
    if (self.gridOn) {
        
        CGPoint prev = [touch previousLocationInView:self];
        CGPoint loc = [touch locationInView:self];
        
        self.previousPreviousPoint = CGPointMake(24*(round(prev.x/24)), 32*(round(prev.y/32)));
        self.previousPoint = CGPointMake(24*(round(prev.x/24)), 32*(round(prev.y/32)));
        self.currentPoint = CGPointMake(24*(round(loc.x/24)), 32*(round(loc.y/32)));
    }
    else {
        self.previousPreviousPoint = [touch previousLocationInView:self];
        self.previousPoint = [touch previousLocationInView:self];
        self.currentPoint = [touch locationInView:self];
    }
        
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, self.currentPoint.x, self.currentPoint.y);
    CGPathAddLineToPoint(subpath, NULL, self.currentPoint.x, self.currentPoint.y);
    
    NSNumber *penType;
    NSNumber *lineColorNumber;
    CGFloat lineWidth;
    
    if (projectVC.erasing) {
        penType = @(0);
        lineColorNumber = @(0);
        lineWidth = 60.0f;
    }
    else {
        penType = @(self.penType);
        lineColorNumber = self.lineColorNumber;
        if (self.penType == 1 ) lineWidth = 2.0f;
        else if (self.penType == 2) lineWidth = 7.0f;
        else lineWidth = 30.0f;
    }
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    NSDictionary *subpathValues =  @{ @"mid1x" : @(self.currentPoint.x),
                                      @"mid1y" : @(self.currentPoint.y),
                                      @"mid2x" : @(self.currentPoint.x),
                                      @"mid2y" : @(self.currentPoint.y),
                                      @"prevx" : @(self.currentPoint.x),
                                      @"prevy" : @(self.currentPoint.y),
                                      @"color" : lineColorNumber,
                                      @"pen" : penType
                                      };
    
    // compute the rect containing the new segment plus padding for drawn line
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -1 * lineWidth, -1 * lineWidth);
    
    [paths addObject:subpathValues];
    [self setNeedsDisplayInRect:drawBox];
    
    [[FirebaseHelper sharedHelper] resetUndo];
    
    NSString *subpathsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@", [FirebaseHelper sharedHelper].db, self.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
    [subpathsRef updateChildValues:@{ dateString  :  subpathValues }];
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
    
    CGPathRelease(subpath);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSArray *allTouches = [[event allTouches] allObjects];
    
    if (allTouches.count > 2) return;
    
    if (allTouches.count == 2 && !projectVC.erasing && projectVC.userRole > 0) {
        
        CGPoint touch1 = [allTouches[0] locationInView:self];
        CGPoint touch2 = [allTouches[1] locationInView:self];
        
        BOOL firstShape = CGRectIsNull(self.shapeRect);

        if (self.gridOn) self.shapeRect = CGRectMake((round(touch1.x/24))*24, (round(touch1.y/32))*32, (round((touch2.x-touch1.x)/24))*24, (round((touch2.y-touch1.y)/32))*32);
        else self.shapeRect = CGRectMake(touch1.x, touch1.y, touch2.x-touch1.x, touch2.y-touch1.y);

        if (firstShape) {
            
            double currentIndexDate = [[[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"currentIndexDate"] doubleValue];
            NSMutableDictionary *subpathsDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid];
            
            for (NSString *dateString in subpathsDict.allKeys) {
                if ([dateString doubleValue] > currentIndexDate) {
                    [subpathsDict removeObjectForKey:dateString];
                    NSString *subpathString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@/%@", [FirebaseHelper sharedHelper].db, self.boardID, [FirebaseHelper sharedHelper].uid, dateString];
                    Firebase *subpathRef = [[Firebase alloc] initWithUrl:subpathString];
                    [subpathRef removeValue];
                }
            }
            
            [[FirebaseHelper sharedHelper]resetUndo];
            [self setNeedsDisplay];
        }
        else {
            
            CGFloat scale = [UIScreen mainScreen].scale;
            
            CGRect bufferRect = CGRectInset(self.shapeRect, MIN(-80*scale, -1*fabs(self.shapeRect.size.width*.2)), MIN(-80*scale,-1*fabs(self.shapeRect.size.height*.2)));
            [self setNeedsDisplayInRect:bufferRect];
        }
        
        return;
    }
    
    if (!self.drawable || self.commenting || [projectVC.chatTextField isFirstResponder] || [[projectVC.view viewWithTag:104] isFirstResponder] || [projectVC.commentTitleTextField isFirstResponder] || self.selectedAvatarUserID) return;
    
    if (projectVC.userRole > 0) [self addUserDrawing:[FirebaseHelper sharedHelper].uid];
    
    UITouch *touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];
    
    if (projectVC.erasing) projectVC.eraserCursor.center = [touch locationInView:projectVC.view];
    
    // if the finger has moved less than the min dist ...
    CGFloat dx = point.x - self.currentPoint.x;
    CGFloat dy = point.y - self.currentPoint.y;
    if ((dx * dx + dy * dy) < kPointMinDistanceSquared) return;
    
    // update points: previousPrevious -> mid1 -> previous -> mid2 -> current
    
    if (self.gridOn) {
        
        CGPoint prev = [touch previousLocationInView:self];
        CGPoint loc = [touch locationInView:self];
        
        self.previousPreviousPoint = CGPointMake(24*(round(self.previousPoint.x/24)), 32*(round(self.previousPoint.y/32)));
        self.previousPoint = CGPointMake(24*(round(prev.x/24)), 32*(round(prev.y/32)));
        self.currentPoint = CGPointMake(24*(round(loc.x/24)), 32*(round(loc.y/32)));
        
    }
    else {
        self.previousPreviousPoint = self.previousPoint;
        self.previousPoint = [touch previousLocationInView:self];
        self.currentPoint = [touch locationInView:self];
    }
    
    CGPoint mid1 = midPoint(self.previousPoint, self.previousPreviousPoint);
    CGPoint mid2 = midPoint(self.currentPoint, self.previousPoint);
    
    NSNumber *penType;
    NSNumber *lineColorNumber;
    CGFloat lineWidth;
    
    if (projectVC.erasing) {
        penType = @(0);
        lineColorNumber = @(0);
        lineWidth = 60.0f;
    }
    else {
        penType = @(self.penType);
        lineColorNumber = self.lineColorNumber;
        if (self.penType == 1 ) lineWidth = 2.0f;
        else if (self.penType == 2) lineWidth = 7.0f;
        else lineWidth = 30.0f;
    }

    CGMutablePathRef subpath = CGPathCreateMutable();
    NSDictionary *subpathValues;
    CGRect bounds;
    
    if (self.gridOn) {
        
        subpathValues = @{ @"currx" : @(self.currentPoint.x),
                           @"curry" : @(self.currentPoint.y),
                           @"prevx" : @(self.previousPoint.x),
                           @"prevy" : @(self.previousPoint.y),
                           @"color" : lineColorNumber,
                           @"pen" : penType
                                       };
        
        CGPathMoveToPoint(subpath, NULL, self.currentPoint.x, self.currentPoint.y);
        CGPathAddLineToPoint(subpath, NULL, self.currentPoint.x, self.currentPoint.y);
        
        bounds = CGRectMake(self.previousPoint.x, self.previousPoint.y, self.currentPoint.x-self.previousPoint.x, self.currentPoint.y-self.previousPoint.y);
    }
    else {
        
        subpathValues = @{ @"mid1x" : @(mid1.x),
                           @"mid1y" : @(mid1.y),
                           @"mid2x" : @(mid2.x),
                           @"mid2y" : @(mid2.y),
                           @"prevx" : @(self.previousPoint.x),
                           @"prevy" : @(self.previousPoint.y),
                           @"color" : lineColorNumber,
                           @"pen" : penType
                            };
        
        CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
        CGPathAddQuadCurveToPoint(subpath, NULL, self.previousPoint.x, self.previousPoint.y, mid2.x, mid2.y);
        
        bounds = CGPathGetBoundingBox(subpath);
    }
    
    CGRect drawBox = CGRectInset(bounds, -1 * lineWidth, -1 * lineWidth);
    
    [paths addObject:subpathValues];
    
    [self setNeedsDisplayInRect:drawBox];

    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *subpathsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@", [FirebaseHelper sharedHelper].db, self.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
    [subpathsRef updateChildValues:@{ dateString  :  subpathValues }];
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
    
    CGPathRelease(subpath);
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (projectVC.userRole == 0 && projectVC.activeCommentThreadID) {

        [self hideChat];
        [projectVC.chatOpenButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
        projectVC.chatOpen = false;
        projectVC.activeCommentThreadID = nil;
        
        iCarousel *carousel;
        
        if (projectVC.versioning) carousel = projectVC.versionsCarousel;
        else carousel = projectVC.carousel;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:.25];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        carousel.center = CGPointMake(projectVC.view.center.x, projectVC.view.center.y);
        
        CGRect backgroundRect = self.avatarBackgroundImage.frame;
        self.avatarBackgroundImage.frame = CGRectMake(18, backgroundRect.origin.y, backgroundRect.size.width, backgroundRect.size.height);
        
        CGRect labelRect = self.userLabel.frame;
        self.userLabel.frame = CGRectMake(95, labelRect.origin.y, labelRect.size.width, labelRect.size.height);
        
        for (AvatarButton *avatar in self.avatarButtons) {
            
            CGRect avatarRect = avatar.frame;
            avatar.frame = CGRectMake(23.25, avatarRect.origin.y, avatarRect.size.width, avatarRect.size.height);
        }

        [UIView commitAnimations];
    }
    
    projectVC.eraserCursor.hidden = true;
    
    if (!self.drawable) return;
    
    if (self.commenting) {
        self.commenting = false;
        self.leaveCommentLabel.hidden = true;
        self.fadeView.hidden = true;
        return;
    }
    
    if ([projectVC.chatTextField isFirstResponder] || [[projectVC.view viewWithTag:104] isFirstResponder] || [projectVC.commentTitleTextField isFirstResponder]) {
        
        projectVC.commentTitleView.hidden = true;
        projectVC.chatOpenButton.hidden = true;
        projectVC.chatFadeImage.hidden = true;
        projectVC.chatTable.hidden = true;
        projectVC.chatView.hidden = true;
        [projectVC.chatTextField resignFirstResponder];
        [[projectVC.view viewWithTag:104] resignFirstResponder];
        [projectVC.commentTitleTextField resignFirstResponder];
        return;
    }
 
    if (!CGRectIsNull(self.shapeRect)) {
        
        [projectVC.view viewWithTag:4].alpha = 1;
        [projectVC.view viewWithTag:3].alpha = .3;
        [projectVC.view viewWithTag:2].alpha = 1;
        
        NSDictionary *subpathValues = @{ @"origx"  : @(self.shapeRect.origin.x),
                                         @"origy"  : @(self.shapeRect.origin.y),
                                         @"width"  : @(self.shapeRect.size.width),
                                         @"height" : @(self.shapeRect.size.height),
                                         @"color"  : self.lineColorNumber,
                                         @"pen"    : @(self.penType),
                                         @"shape"  : @(self.shapeType)
                                         };
    
        self.shapeRect = CGRectNull;
    
        [paths addObject:subpathValues];
        
        NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
        NSString *subpathsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@", [FirebaseHelper sharedHelper].db, self.boardID, [FirebaseHelper sharedHelper].uid];
        Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
        [subpathsRef updateChildValues:@{ dateString  :  subpathValues }];
        [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
    }

    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@", [FirebaseHelper sharedHelper].db, self.boardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    
    NSDictionary *penUpDict = @{dateString : @"penUp"};
    
    [paths addObject:penUpDict];
    [self setNeedsDisplay];
    
    NSString *subpathsString = [NSString stringWithFormat:@"subpaths/%@", [FirebaseHelper sharedHelper].uid];
    [[boardRef childByAppendingPath:subpathsString] updateChildValues:penUpDict];
    
    NSMutableDictionary *undoDict = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"undo"];
    int undoTotal = [[[undoDict objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"total"] intValue];
    undoTotal++;
    
    NSMutableDictionary *newUndoDict = [@{ @"currentIndex" : @0,
                                           @"currentIndexDate" : dateString,
                                           @"total" : @(undoTotal)
                                           } mutableCopy];
    
    [undoDict setObject:newUndoDict forKey:[FirebaseHelper sharedHelper].uid];
    
    NSString *undoString = [NSString stringWithFormat:@"undo/%@", [FirebaseHelper sharedHelper].uid];
    [[boardRef childByAppendingPath:undoString] setValue:newUndoDict];
    
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@"penUp" forKey:dateString];
    
    [[FirebaseHelper sharedHelper] setBoard:self.boardID UpdatedAt:dateString];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self touchesEnded:touches withEvent:event];
}

- (void)drawRect:(CGRect)rect {

    if (self.gridOn) [[UIColor clearColor] set];
    else [[UIColor whiteColor] set];
    UIRectFill(rect);

    if (!self.drawingBoard) {
    
        CGFloat scale = [UIScreen mainScreen].scale;
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(incrementalImage.CGImage, CGRectMake(rect.origin.x*scale, rect.origin.y*scale, rect.size.width*scale, rect.size.height*scale));
        UIImage *incrementalImageCropped = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        [incrementalImageCropped drawInRect:rect];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    
    UIColor *lineColor;
    CGFloat lineWidth = 0;

    if (!CGRectIsNull(self.shapeRect)) {
        
        CGFloat alpha = 1;
        
        if (self.penType == 0) {
            lineWidth = 60.0f;
            alpha = 1.0f;
        }
        if (self.penType == 1) {
            lineWidth = 1.0f;
            alpha = 1.0f;
        }
        if (self.penType == 2) {
            lineWidth = 7.0f;
            alpha = 1.0f;
        }
        if (self.penType == 3) {
            lineWidth = 40.0f;
            alpha = 0.4f;
        }
        
        if (self.lineColorNumber.intValue == 1) lineColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:alpha];
        if (self.lineColorNumber.intValue == 2) lineColor = [UIColor colorWithRed:(12.0f/255.0f) green:(111.0f/255.0f) blue:(234.0f/255.0f) alpha:alpha];
        if (self.lineColorNumber.intValue == 3) lineColor = [UIColor colorWithRed:(225.0f/255.0f) green:(34.0f/255.0f) blue:(34.0f/255.0f) alpha:alpha];
        if (self.lineColorNumber.intValue == 4) lineColor = [UIColor colorWithRed:(117.0f/255.0f) green:(228.0f/255.0f) blue:(117.0f/255.0f) alpha:alpha];
        if (self.lineColorNumber.intValue == 5) lineColor = [UIColor colorWithRed:(255.0f/255.0f) green:(246.0f/255.0f) blue:0.0f alpha:alpha];
        
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextSetLineWidth(context, lineWidth);
        
        if (self.shapeType == 1) CGContextStrokeRect(context, self.shapeRect);
        else if (self.shapeType == 2) CGContextStrokeEllipseInRect(context, self.shapeRect);
        else if (self.shapeType == 3) {
            CGPoint points[2] = { self.shapeRect.origin, CGPointMake(self.shapeRect.origin.x+self.shapeRect.size.width, self.shapeRect.origin.y+self.shapeRect.size.height) };
            CGContextStrokeLineSegments(context, points, 2);
        }
        
        return;
    }

    for (int i=0; i<paths.count; i++) {
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        
        NSDictionary *subpathValues = paths[i];
        
        if (subpathValues.allKeys.count == 1) {
            
            if (i>0) {
                
                NSDictionary *prevSubpathValues = paths[i-1];
                int prevColorNumber = [[prevSubpathValues objectForKey:@"color"] intValue];
                if (prevSubpathValues.allKeys.count > 1 && prevColorNumber == 0 && self.gridOn) CGContextSetBlendMode(context, kCGBlendModeClear);
            }
            
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextSetLineWidth(context, lineWidth);
            CGContextStrokePath(context);
            CGContextBeginPath(context);
            
            if (!self.drawingBoard && i == paths.count-1) {
                
                CGImageRef imageRef = CGBitmapContextCreateImage(context);
                incrementalImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                
                paths = [NSMutableArray array];
            }
            
            continue;
        }

        int penType = [[subpathValues objectForKey:@"pen"] intValue];
        CGFloat alpha = 1;
        
        if (penType == 0) {
            lineWidth = 60.0f;
            alpha = 1.0f;
        }
        if (penType == 1) {
            lineWidth = 1.0f;
            alpha = 1.0f;
        }
        if (penType == 2) {
            lineWidth = 7.0f;
            alpha = 1.0f;
        }
        if (penType == 3) {
            lineWidth = 40.0f;
            alpha = 0.4f;
        }
        
        int colorNumber = [[subpathValues objectForKey:@"color"] intValue];
        
        if (colorNumber == 0) lineColor = [UIColor whiteColor];
        if (colorNumber == 1) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(220.0f/255.0f) green:(220.0f/255.0f) blue:(220.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:alpha];
        }
        if (colorNumber == 2) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(183.0f/255.0f) green:(206.0f/255.0f) blue:(234.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:(12.0f/255.0f) green:(111.0f/255.0f) blue:(234.0f/255.0f) alpha:alpha];
        }
        if (colorNumber == 3) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(225.0f/255.0f) green:(175.0f/255.0f) blue:(175.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:(225.0f/255.0f) green:(34.0f/255.0f) blue:(34.0f/255.0f) alpha:alpha];
        }
        if (colorNumber == 4) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(194.0f/255.0f) green:(228.0f/255.0f) blue:(176.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:(117.0f/255.0f) green:(228.0f/255.0f) blue:(117.0f/255.0f) alpha:alpha];
        }
        if (colorNumber == 5) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(255.0f/255.0f) green:(253.0f/255.0f) blue:(197.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:(255.0f/255.0f) green:(246.0f/255.0f) blue:0.0f alpha:alpha];
        }
        
        CGMutablePathRef subpath = CGPathCreateMutable();
        
        if ([subpathValues.allKeys containsObject:@"mid1x"]) {
            
            CGPathMoveToPoint(subpath, NULL, [[subpathValues objectForKey:@"mid1x"] floatValue], [[subpathValues objectForKey:@"mid1y"] floatValue]);
            CGPathAddQuadCurveToPoint(subpath, NULL,
                                      [[subpathValues objectForKey:@"prevx"] floatValue], [[subpathValues objectForKey:@"prevy"] floatValue],
                                      [[subpathValues objectForKey:@"mid2x"] floatValue], [[subpathValues objectForKey:@"mid2y"] floatValue]);
        }
        else if ([subpathValues.allKeys containsObject:@"shape"]) {
            
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextSetLineWidth(context, lineWidth);
            
            int shapeType = [[subpathValues objectForKey:@"shape"] intValue];
            
            CGRect shapeRect = CGRectMake([[subpathValues objectForKey:@"origx"] floatValue], [[subpathValues objectForKey:@"origy"] floatValue], [[subpathValues objectForKey:@"width"] floatValue], [[subpathValues objectForKey:@"height"] floatValue]);
            
            if (shapeType == 1) CGContextStrokeRect(context, shapeRect);
            else if (shapeType == 2) CGContextStrokeEllipseInRect(context, shapeRect);
            else if (shapeType == 3) {
                CGPoint points[2] = { shapeRect.origin, CGPointMake(shapeRect.origin.x+shapeRect.size.width, shapeRect.origin.y+shapeRect.size.height) };
                CGContextStrokeLineSegments(context, points, 2);
            }
        }
        else if ([subpathValues.allKeys containsObject:@"currx"]) {
            
            CGPathMoveToPoint(subpath, NULL, [[subpathValues objectForKey:@"prevx"] floatValue], [[subpathValues objectForKey:@"prevy"] floatValue]);
            CGPathAddLineToPoint(subpath, NULL, [[subpathValues objectForKey:@"currx"] floatValue], [[subpathValues objectForKey:@"curry"] floatValue]);
        }
        
        CGContextAddPath(context, subpath);
        
        if (i == paths.count-1 && subpathValues.count != 7) {

            if (colorNumber == 0 && self.gridOn) CGContextSetBlendMode(context, kCGBlendModeClear);
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextSetLineWidth(context, lineWidth);
            CGContextStrokePath(context);
        }
        
        CGPathRelease(subpath);
    }
}

-(void) drawSubpath:(NSDictionary *)subpathValues {

    CGMutablePathRef subpath = CGPathCreateMutable();
    
    CGRect bounds;
    
    if ([subpathValues.allKeys containsObject:@"mid1x"]) {
        
        CGPoint mid1;
        CGPoint mid2;
        CGPoint prev;
        
        mid1.x = [[subpathValues objectForKey:@"mid1x"] floatValue];
        mid1.y = [[subpathValues objectForKey:@"mid1y"] floatValue];
        mid2.x = [[subpathValues objectForKey:@"mid2x"] floatValue];
        mid2.y = [[subpathValues objectForKey:@"mid2y"] floatValue];
        prev.x = [[subpathValues objectForKey:@"prevx"] floatValue];
        prev.y = [[subpathValues objectForKey:@"prevy"] floatValue];
        
        CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
        CGPathAddQuadCurveToPoint(subpath, NULL,
                                  prev.x, prev.y,
                                  mid2.x, mid2.y);
        bounds = CGPathGetBoundingBox(subpath);
    }
    else if ([subpathValues.allKeys containsObject:@"currx"]) {
        
        CGPoint curr;
        CGPoint prev;
        
        curr.x = [[subpathValues objectForKey:@"currx"] floatValue];
        curr.y = [[subpathValues objectForKey:@"curry"] floatValue];
        prev.x = [[subpathValues objectForKey:@"prevx"] floatValue];
        prev.y = [[subpathValues objectForKey:@"prevy"] floatValue];
        
        CGPathMoveToPoint(subpath, NULL, curr.x, curr.y);
        CGPathAddLineToPoint(subpath, NULL, curr.x, curr.y);
        
        bounds = CGRectMake(prev.x, prev.y, curr.x-prev.x, curr.y-prev.y);
    }
    else if ([subpathValues.allKeys containsObject:@"shape"]) bounds = self.bounds;
    
    [paths addObject:subpathValues];
    
    int penType = [[subpathValues objectForKey:@"pen"] intValue];
    CGFloat lineWidth = 0;
    
    if (penType == 1 ) lineWidth = 2.0f;
    else if (penType == 2) lineWidth = 7.0f;
    else lineWidth = 30.0f;
    
    CGRect drawBox = CGRectInset(bounds, -1 * lineWidth, -1 * lineWidth);
    [self setNeedsDisplayInRect:drawBox];
    
    CGPathRelease(subpath);
}

-(void) hideChat {
    
    [projectVC.view bringSubviewToFront:projectVC.gridImageView];
    [projectVC.view bringSubviewToFront:projectVC.carousel];
    [projectVC.view bringSubviewToFront:projectVC.versionsCarousel];
    [projectVC.view bringSubviewToFront:projectVC.feedbackBackground];
    [projectVC.view bringSubviewToFront:projectVC.feedbackButton];
    [projectVC showDrawMenu];
    projectVC.carouselOffset = 0;
    
    for (int i=6; i<=10; i++) {
        
        if (i==8 || i==9) continue;
        
        UIView *button = [projectVC.view viewWithTag:i];
        if (i==6) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
    
    for (CommentButton *commentButton in self.commentButtons) {
        
        commentButton.commentImage.hidden = false;
        commentButton.highlightedImage.hidden = true;
        commentButton.deleteButton.hidden = true;
    }

    if (projectVC.userRole == 0) {
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .25 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            projectVC.chatOpenButton.center = CGPointMake(512, 598);
            projectVC.chatFadeImage.center = CGPointMake(512, 616);
            projectVC.chatView.frame = CGRectMake(0, 719, 1024, 152);
            projectVC.chatTable.frame = CGRectMake(0, 612, projectVC.view.frame.size.width, 107+projectVC.chatDiff);
            projectVC.commentTitleView.frame = CGRectMake(0, 613, 1024, 50);
        });
    }
}

-(void) addCommentAtPoint:(CGPoint)point {
    
    self.fadeView.hidden = true;
    
    [Flurry logEvent:@"Comment_Thread-Created" withParameters:@{@"userID":[FirebaseHelper sharedHelper].uid,
                                                                @"boardID":self.boardID,
                                                                @"projectID":[FirebaseHelper sharedHelper].currentProjectID,
                                                                @"teamID":[FirebaseHelper sharedHelper].teamID
                                                                }];
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:projectVC.activeBoardID] objectForKey:@"commentsID"];
    
    NSDictionary *commentDict = @{ @"location" : [@{ @"x" : @(point.x),
                                                    @"y" : @(point.y)
                                                    } mutableCopy],
                                   @"owner" : [FirebaseHelper sharedHelper].uid,
                                   @"title" : @""
                                   };
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *commentThreadString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@", [FirebaseHelper sharedHelper].db, commentsID];
    Firebase *commentThreadRef = [[Firebase alloc] initWithUrl:commentThreadString];
    
    Firebase *commentThreadRefWithID = [commentThreadRef childByAutoId];
    [commentThreadRefWithID setValue:@{ @"info" : commentDict,
                                        @"updatedAt" : dateString
                                        }];
    
    NSMutableDictionary *mutableCommentDict = [commentDict mutableCopy];
    [mutableCommentDict setObject:dateString forKey:@"updatedAt"];

    [[FirebaseHelper sharedHelper] setCommentThread:commentThreadRefWithID.key updatedAt:dateString];
    [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] setObject:mutableCommentDict forKey:commentThreadRefWithID.key];
    [[FirebaseHelper sharedHelper] observeCommentThreadWithID:commentThreadRefWithID.key boardID:self.boardID];

    CommentButton *button = [CommentButton buttonWithType:UIButtonTypeCustom];
    button.commentThreadID = commentThreadRefWithID.key;
    button.point = point;
    button.userID = [FirebaseHelper sharedHelper].uid;
    [button generateIdenticon];
    button.frame = CGRectMake(0, 0, button.userImage.size.width, button.userImage.size.height);
    button.center = CGPointMake(point.x-40, point.y+22);
    CGAffineTransform tr = CGAffineTransformScale(button.transform, .25, .25);
    tr = CGAffineTransformRotate(tr, -M_PI_2);
    button.transform = tr;
    
    UIImage *avatarImage = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:button.userID] objectForKey:@"avatar"];
    
    if ([avatarImage isKindOfClass:[UIImage class]]) {
        
        UIImageView *customAvatar = [[UIImageView alloc] initWithImage:avatarImage];
        customAvatar.frame = CGRectMake(15, 0, 225, 225);
        [button addSubview:customAvatar];
        [button sendSubviewToBack:customAvatar];
        customAvatar.layer.cornerRadius = 110;
        customAvatar.layer.masksToBounds = YES;
        
        button.imageView.hidden = true;
        button.identiconView.hidden = true;
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(commentLongPress:)];
    longPress.minimumPressDuration = .2;
    [button addGestureRecognizer:longPress];
    
    [self addSubview:button];
    
    [self.commentButtons addObject:button];
    
    [button commentTapped];
}

-(void) commentLongPress:(UILongPressGestureRecognizer*)sender {
    
    CommentButton *button = (CommentButton *)sender.view;
    CGPoint point = [sender locationInView:self];

    CGPoint pointForTargetView = [button.deleteButton convertPoint:point fromView:self];
    if (CGRectContainsPoint(button.deleteButton.bounds, pointForTargetView)) return;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        button.commentTitleLabel.hidden = true;
        
        for (CommentButton *commentButton in self.commentButtons) {
            
            if ([commentButton isEqual:button]) continue;
            
            commentButton.deleteButton.hidden = true;
            commentButton.commentImage.hidden = false;
            commentButton.highlightedImage.hidden = true;
        }
        
        [self bringSubviewToFront:button];
        
        [UIView animateWithDuration:.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             
                             CGAffineTransform tr = button.transform;
                             tr = CGAffineTransformScale(tr, 1.25, 1.25);
                             button.transform = tr;
                             
                             button.center = point;
                             
                         } completion:nil];
    }
    
    if ( sender.state == UIGestureRecognizerStateChanged ) {
        
        button.center = point;
    }
    
    if ( sender.state == UIGestureRecognizerStateEnded ) {
        
        [UIView animateWithDuration:.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             
                             CGAffineTransform tr = button.transform;
                             tr = CGAffineTransformScale(tr, 1/1.25, 1/1.25);
                             button.transform = tr;
                             
                             button.center = CGPointMake(button.center.x+9, button.center.y-6);
                         }
         
                         completion:^(BOOL finished) {
                             
                             if ([projectVC.chatTextField isFirstResponder]) {
                                 button.deleteButton.hidden = false;
                                 button.commentImage.hidden = true;
                                 button.highlightedImage.hidden = false;
                             }
                             
                             button.center = CGPointMake(MAX(0,MIN(button.center.x,768)), MAX(0,MIN(button.center.y,1024)));
                             
                             button.point = CGPointMake(MAX(0,MIN(button.center.x,768))+40, button.center.y-22);
                             
                             [button updateLabel];
                             
                             if (projectVC.keyboardHeight > 0) [self updateCarouselOffsetWithPoint:button.point];
                             
                             NSDictionary *locationDict = @{ @"x" : @(button.point.x), @"y" : @(button.point.y) };
                             
                             NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"commentsID"];
                             
                             [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:button.commentThreadID] setObject:[locationDict mutableCopy] forKey:@"location"];
                             
                             NSString *locationString = [NSString stringWithFormat:@"https://%@.firebaseio.com/comments/%@/%@/info/location", [FirebaseHelper sharedHelper].db, commentsID, button.commentThreadID];
                             Firebase *locationRef = [[Firebase alloc] initWithUrl:locationString];
                             [locationRef setValue:locationDict];
                         }];
    }
}

-(void) addUserDrawing:(NSString *)userID {
    
    self.drawingUserID = userID;
    
    if (![userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        self.drawable = false;
        self.fadeView.hidden = false;
        [self bringSubviewToFront:self.fadeView];
    }
    
    for (AvatarButton *avatar in self.avatarButtons) {
        
        if ([avatar.userID isEqualToString:userID]) {
            avatar.drawingImage.hidden = false;
            
            if (!avatar.scaled) {
                
                [self bringSubviewToFront:avatar];
                CGAffineTransform tr = CGAffineTransformScale(avatar.transform, 1.3, 1.3);
                //tr = CGAffineTransformRotate(tr, -M_PI_2);
                avatar.transform = tr;
                avatar.scaled = true;
            }
        }
    }
    
    if (![userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
        
        for (int i=0; i<=projectVC.drawButtons.count; i++) {
            
            UIButton *button = (UIButton *)[projectVC.view viewWithTag:i+2];
            button.userInteractionEnabled = NO;
            button.alpha = .2;
        }
    }
    
    for (NSString *uid in self.drawingTimers.allKeys) {
        
        if ([userID isEqualToString:uid]) {
        
            NSTimer *oldTimer = [self.drawingTimers objectForKey:userID];
            [oldTimer invalidate];
        }
    }

    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(removeUserDrawing:) userInfo:userID repeats:NO];
    [self.drawingTimers setObject:timer forKey:userID];
}

-(void) removeUserDrawing:(NSTimer *)timer {

    self.drawingUserID = nil;
    
    self.drawable = true;
    if (!self.commenting) self.fadeView.hidden = true;
    
    NSString *userID = timer.userInfo;
    
    for (AvatarButton *avatar in self.avatarButtons) {
        
        if ([avatar.userID isEqualToString:userID]) {
            avatar.drawingImage.hidden = true;
            
            if (avatar.scaled) {
                CGAffineTransform tr = CGAffineTransformScale(avatar.transform, 1/1.3, 1/1.3);
                //tr = CGAffineTransformRotate(tr, -M_PI_2);
                avatar.transform = tr;
                avatar.scaled = false;
            }
        }
    }
    
    for (int i=0; i<=projectVC.drawButtons.count; i++) {
        
        UIButton *button = (UIButton *)[projectVC.view viewWithTag:i+2];
        button.userInteractionEnabled = YES;
        button.alpha = 1;
        
        if (i==0 && ![projectVC canUndo]) button.alpha = .3;
        else if (i==1 && ![projectVC canRedo]) button.alpha = .3;
        else if (i==2 && ![projectVC canClear]) button.alpha = .3;
        else if (i==7 && !self.gridOn) button.alpha = .3;
    }
    
    self.alpha = 1;
    
    [self.drawingTimers removeObjectForKey:userID];
    
    if (self.shouldRedraw) [projectVC drawBoard:self];
    
    self.shouldRedraw = false;
}

-(void) avatarTapped:(id)sender {
    
    AvatarButton *avatar = (AvatarButton *)sender;

    for (AvatarButton *avtr in self.avatarButtons) {
        avtr.highlightedImage.hidden = true;
    }
    
    if  ([avatar.userID isEqualToString:self.selectedAvatarUserID]) {
        
        self.userLabel.text = nil;
        self.userLabel.hidden = true;
        
        self.selectedAvatarUserID = nil;
    }
    else {
        
        NSString *nameString = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"name"];
        self.userLabel.text = nameString;
        [self.userLabel sizeToFit];
        self.userLabel.center = CGPointMake(self.userLabel.center.x, avatar.center.y);
        
        CGRect nameRect = [self.userLabel.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Semibold" size:20]} context:nil];
        
        CGFloat diff = self.userLabel.center.y-nameRect.size.width/2;
        
        if (diff < 10) self.userLabel.center = CGPointMake(self.userLabel.center.x, self.userLabel.center.y-diff+10);
        
        self.userLabel.hidden = false;
        self.userLabel.hidden = false;
        
        avatar.highlightedImage.hidden = false;
        self.selectedAvatarUserID = avatar.userID;
    }
    
    [projectVC drawBoard:self];
}

-(void) updateCarouselOffsetWithPoint:(CGPoint)point {
    
    iCarousel *carousel;

    if (projectVC.versioning) carousel = projectVC.versionsCarousel;
    else carousel = projectVC.carousel;
    
    float oldOffset = projectVC.carouselOffset;
    
    if (projectVC.userRole > 0) projectVC.carouselOffset = (point.x*.75)-70;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    if (projectVC.userRole == 0) {
        
        float chatHeight = projectVC.chatTable.frame.size.height;
        
        if ((point.x > 768-chatHeight || oldOffset > chatHeight) && !projectVC.chatOpen) {
            
            projectVC.carouselOffset = chatHeight;
            
            CGRect carouselRect = carousel.frame;
            carousel.frame = CGRectMake(carouselRect.origin.x, 5-projectVC.carouselOffset, carouselRect.size.width, carouselRect.size.height);
            
            CGRect backgroundRect = self.avatarBackgroundImage.frame;
            self.avatarBackgroundImage.frame = CGRectMake(17+projectVC.carouselOffset, backgroundRect.origin.y, backgroundRect.size.width, backgroundRect.size.height);
            
            CGRect labelRect = self.userLabel.frame;
            self.userLabel.frame = CGRectMake(94+projectVC.carouselOffset, labelRect.origin.y, labelRect.size.width, labelRect.size.height);
            
            for (AvatarButton *avatar in self.avatarButtons) {
                
                CGRect avatarRect = avatar.frame;
                avatar.frame = CGRectMake(22.25+projectVC.carouselOffset, avatarRect.origin.y, avatarRect.size.width, avatarRect.size.height);
            }
        }

    }
    else if (projectVC.activeCommentThreadID && projectVC.carouselOffset > 0) {
        
        CGRect carouselRect = carousel.frame;
        carouselRect.origin.y += (oldOffset - projectVC.carouselOffset);
        carousel.frame = carouselRect;
        
        CGRect backgroundRect = self.avatarBackgroundImage.frame;
        backgroundRect.origin.x -= (oldOffset - projectVC.carouselOffset);
        self.avatarBackgroundImage.frame = backgroundRect;

        CGRect labelRect = self.userLabel.frame;
        labelRect.origin.x -= (oldOffset - projectVC.carouselOffset);
        self.userLabel.frame = labelRect;
        
        for (AvatarButton *avatar in self.avatarButtons) {
            
            CGRect avatarRect = avatar.frame;
            avatarRect.origin.x -= (oldOffset - projectVC.carouselOffset);
            avatar.frame = avatarRect;
        }
    }
    
    [UIView commitAnimations];
}

#pragma mark interface

-(void)clear {
    
    paths = [NSMutableArray array];
    incrementalImage = nil;
    [self setNeedsDisplay];
}

-(UIImage *) generateImage {
    
    [self viewWithTag:1].hidden = true;
    for (CommentButton *comment in self.commentButtons) {
        if (comment.commentTitleLabel.text.length == 0) comment.hidden = YES;
    }
    

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(768, 1024), YES, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *boardImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    for (CommentButton *comment in self.commentButtons) comment.hidden = NO;
    [self viewWithTag:1].hidden = false;
   
    CGRect newRect = CGRectMake(0, 0, 1024, 768);
    UIGraphicsBeginImageContextWithOptions(newRect.size, YES, 0.0);
    [[UIImage imageWithCGImage:boardImage.CGImage scale:1.0 orientation:UIImageOrientationRight] drawInRect:newRect];
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rotatedImage;
}

@end
