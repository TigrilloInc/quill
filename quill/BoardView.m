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

#define DEFAULT_COLOR               [UIColor blackColor]
#define DEFAULT_BACKGROUND_COLOR    [UIColor whiteColor]

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
}

#pragma mark UIView lifecycle methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        //self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
        self.penType = 1;
        self.lineColorNumber = @1;
        _empty = YES;
        self.activeUserIDs = [NSMutableArray array];
        self.loadingView = nil;
        
        projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;;
        
        if (projectVC.userRole > 0) self.drawable = true;
        else self.drawable = false;
        
        self.selectedAvatarUserID = nil;
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
        CGAffineTransform bgtr = CGAffineTransformScale(self.avatarBackgroundImage.transform, .25, .25);
        bgtr = CGAffineTransformRotate(bgtr, -M_PI_2);
        self.avatarBackgroundImage.transform = bgtr;
        self.avatarBackgroundImage.frame = CGRectMake(18, self.avatarBackgroundImage.frame.size.width-70, self.avatarBackgroundImage.frame.size.width, self.avatarBackgroundImage.frame.size.height);
        [self addSubview:self.avatarBackgroundImage];
    }

    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        [avatar generateIdenticonWithShadow:true];
        avatar.frame = CGRectMake(-70.5, -12+(i-1)*66, avatar.userImage.size.width, avatar.userImage.size.height);
        CGAffineTransform tr = CGAffineTransformScale(avatar.transform, .25, .25);
        tr = CGAffineTransformRotate(tr, -M_PI_2);
        avatar.transform = tr;
        if (![self.activeUserIDs containsObject:avatar.userID]) avatar.alpha = 0.5;
        [avatar addTarget:self action:@selector(avatarTapped:) forControlEvents:UIControlEventTouchUpInside];
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
        [button addTarget:self action:@selector(commentTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([button.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(commentLongPress:)];
            longPress.minimumPressDuration = .2;
            [button addGestureRecognizer:longPress];
        }
        
        if ([commentThreadID isEqualToString:projectVC.activeCommentThreadID]) {
            
            button.commentImage.hidden = true;
            button.highlightedImage.hidden = false;
            button.deleteButton.hidden = false;
            
            [self updateCarouselOffsetWithPoint:button.point];
        }
        
        [self addSubview:button];
        [self.commentButtons addObject:button];
    }
    
    [self bringSubviewToFront:[self viewWithTag:1]];
}

#pragma mark private Helper function

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

#pragma mark Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSArray *allTouches = [[event allTouches] allObjects];
    
    if (allTouches.count > 1 || !self.drawable) return;
    
    UITouch *touch = [touches anyObject];
    
    if (self.selectedAvatarUserID) {
        
        for (AvatarButton *avtr in self.avatarButtons) avtr.highlightedImage.hidden = true;
        
        self.selectedAvatarUserID = nil;
        [projectVC drawBoard:self];
    }
    
    if ([projectVC.chatTextField isFirstResponder]) return;
    
    if (self.commenting) {
        
        [self addCommentAtPoint:[touch locationInView:self]];
        return;
    }
    
    if (projectVC.userRole > 0) [self addUserDrawing];
    
    // initializes our point records to current location
    self.previousPreviousPoint = [touch previousLocationInView:self];
    self.previousPoint = [touch previousLocationInView:self];
    self.currentPoint = [touch locationInView:self];
    
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, self.currentPoint.x, self.currentPoint.y);
    CGPathAddLineToPoint(subpath, NULL, self.currentPoint.x, self.currentPoint.y);
    
    NSNumber *penType;
    NSNumber *lineColorNumber;
    CGFloat lineWidth;
    
    if (projectVC.erasing) {
        penType = @(0);
        lineColorNumber = @(0);
        lineWidth = 120.0f;
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
    CGRect drawBox = CGRectInset(bounds, -2.0 * lineWidth, -2.0 * lineWidth);
    
    [self.paths addObject:subpathValues];
    [self setNeedsDisplayInRect:drawBox];
    
    NSString *subpathsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/subpaths/%@", self.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
    [subpathsRef updateChildValues:@{ dateString  :  subpathValues }];
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
    
    [[FirebaseHelper sharedHelper] resetUndo];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSArray *allTouches = [[event allTouches] allObjects];
    
    if (allTouches.count > 1 || !self.drawable || self.commenting || [projectVC.chatTextField isFirstResponder] || self.selectedAvatarUserID) return;
    
    UITouch *touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];
    
    // if the finger has moved less than the min dist ...
    CGFloat dx = point.x - self.currentPoint.x;
    CGFloat dy = point.y - self.currentPoint.y;
    if ((dx * dx + dy * dy) < kPointMinDistanceSquared) return;
    
    // update points: previousPrevious -> mid1 -> previous -> mid2 -> current
    self.previousPreviousPoint = self.previousPoint;
    self.previousPoint = [touch previousLocationInView:self];
    self.currentPoint = [touch locationInView:self];
    
    CGPoint mid1 = midPoint(self.previousPoint, self.previousPreviousPoint);
    CGPoint mid2 = midPoint(self.currentPoint, self.previousPoint);
    
    NSNumber *penType;
    NSNumber *lineColorNumber;
    CGFloat lineWidth;
    
    if (projectVC.erasing) {
        penType = @(0);
        lineColorNumber = @(0);
        lineWidth = 120.0f;
    }
    else {
        penType = @(self.penType);
        lineColorNumber = self.lineColorNumber;
        if (self.penType == 1 ) lineWidth = 2.0f;
        else if (self.penType == 2) lineWidth = 7.0f;
        else lineWidth = 30.0f;
    }

    NSDictionary *subpathValues =  @{ @"mid1x" : @(mid1.x),
                                      @"mid1y" : @(mid1.y),
                                      @"mid2x" : @(mid2.x),
                                      @"mid2y" : @(mid2.y),
                                      @"prevx" : @(self.previousPoint.x),
                                      @"prevy" : @(self.previousPoint.y),
                                      @"color" : lineColorNumber,
                                      @"pen" : penType
                                      };
   
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL,
                              self.previousPoint.x, self.previousPoint.y,
                              mid2.x, mid2.y);
    
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * lineWidth, -2.0 * lineWidth);
    
    [self.paths addObject:subpathValues];
    [self setNeedsDisplayInRect:drawBox];

    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSString *subpathsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/subpaths/%@", self.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
    [subpathsRef updateChildValues:@{ dateString  :  subpathValues }];
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"subpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.drawable) return;
    
    if (self.commenting) {
        
        self.commenting = false;
        return;
    }
    
    if ([projectVC.chatTextField isFirstResponder]) {
        
        [projectVC.chatTextField resignFirstResponder];
        return;
    }
    
    [self performSelector:@selector(removeUserDrawing) withObject:nil afterDelay:1.0];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", self.boardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    
    NSDictionary *penUpDict = @{ dateString  :  @"penUp" };
    
    [self.paths addObject:penUpDict];
    
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
    
    [[FirebaseHelper sharedHelper] setProjectUpdatedAt];
    [[FirebaseHelper sharedHelper] setActiveBoardUpdatedAt];
}

- (void)drawRect:(CGRect)rect {

    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);
    
    // get the graphics context and draw the path
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    
    UIColor *lineColor;
    CGFloat lineWidth = 0;
    
    for (NSDictionary *subpathValues in self.paths) {

        if (subpathValues.allKeys.count == 1) {
            
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextSetLineWidth(context, lineWidth);
            CGContextStrokePath(context);
            CGContextBeginPath(context);
            
            continue;
        }
        
        CGMutablePathRef subpath = CGPathCreateMutable();
        CGPathMoveToPoint(subpath, NULL, [[subpathValues objectForKey:@"mid1x"] floatValue], [[subpathValues objectForKey:@"mid1y"] floatValue]);
        CGPathAddQuadCurveToPoint(subpath, NULL,
                                  [[subpathValues objectForKey:@"prevx"] floatValue], [[subpathValues objectForKey:@"prevy"] floatValue],
                                  [[subpathValues objectForKey:@"mid2x"] floatValue], [[subpathValues objectForKey:@"mid2y"] floatValue]);
        CGContextAddPath(context, subpath);
        
        int penType = [[subpathValues objectForKey:@"pen"] intValue];
        CGFloat alpha = 1;
        
        if (penType == 0) {
            lineWidth = 120.0f;
            alpha = 1.0f;
        }
        if (penType == 1) {
            lineWidth = 2.0f;
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
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(200.0f/255.0f) green:(230.0f/255.0f) blue:1.0f alpha:alpha];
            else lineColor = [UIColor colorWithRed:0.0f green:(60.0f/255.0f) blue:1.0f alpha:alpha];
        }
        if (colorNumber == 3) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:1.0f green:(200.0f/255.0f) blue:(200.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alpha];
        }
        if (colorNumber == 4) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(230.0f/255.0f) green:1.0f blue:(200.0f/255.0f) alpha:alpha];
            else lineColor = [UIColor colorWithRed:(60.0f/255.0f) green:1.0f blue:0.0f alpha:alpha];
        }
        
        if ([subpathValues isEqual:self.paths.lastObject]) {
            
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextSetLineWidth(context, lineWidth);
            CGContextStrokePath(context);
            CGContextBeginPath(context);
        }
    }
}

-(void) drawSubpath:(NSDictionary *)subpathValues {

    CGPoint mid1;
    CGPoint mid2;
    CGPoint prev;
    
    mid1.x = [[subpathValues objectForKey:@"mid1x"] floatValue];
    mid1.y = [[subpathValues objectForKey:@"mid1y"] floatValue];
    mid2.x = [[subpathValues objectForKey:@"mid2x"] floatValue];
    mid2.y = [[subpathValues objectForKey:@"mid2y"] floatValue];
    prev.x = [[subpathValues objectForKey:@"prevx"] floatValue];
    prev.y = [[subpathValues objectForKey:@"prevy"] floatValue];
    
    int penType = [[subpathValues objectForKey:@"pen"] intValue];
    CGFloat lineWidth = 0;
    
    if (penType == 1 ) lineWidth = 2.0f;
    else if (penType == 2) lineWidth = 7.0f;
    else lineWidth = 30.0f;
    
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL,
                              prev.x, prev.y,
                              mid2.x, mid2.y);
    
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * lineWidth, -2.0 * lineWidth);
    
    [self.paths addObject:subpathValues];
    [self setNeedsDisplayInRect:drawBox];
    
}

-(void) hideChat {
    
    [projectVC.view bringSubviewToFront:projectVC.carousel];
    [projectVC showDrawMenu];
    projectVC.carouselOffset = 0;
    
    for (int i=5; i<=8; i++) {
        
        if (i==7) continue;
        
        UIView *button = [projectVC.view viewWithTag:i];
        if (i==5) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
    
    for (CommentButton *commentButton in self.commentButtons) {
        
        commentButton.commentImage.hidden = false;
        commentButton.highlightedImage.hidden = true;
        commentButton.deleteButton.hidden = true;
    }
}

-(void) addCommentAtPoint:(CGPoint)point {
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:projectVC.activeBoardID] objectForKey:@"commentsID"];
    
    NSDictionary *commentDict = @{ @"location" : [@{ @"x" : @(point.x),
                                                    @"y" : @(point.y)
                                                    } mutableCopy],
                                   @"owner" : [FirebaseHelper sharedHelper].uid
                                   };
    
    NSString *commentThreadString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
    Firebase *commentThreadRef = [[Firebase alloc] initWithUrl:commentThreadString];
    
    Firebase *commentThreadRefWithID = [commentThreadRef childByAutoId];
    [commentThreadRefWithID setValue:@{ @"info" : commentDict }];
    
    [[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] setObject:[commentDict mutableCopy] forKey:commentThreadRefWithID.name];
    [[FirebaseHelper sharedHelper] observeCommentThreadWithID:commentThreadRefWithID.name boardID:self.boardID];
    
    CommentButton *button = [CommentButton buttonWithType:UIButtonTypeCustom];
    button.commentThreadID = commentThreadRefWithID.name;
    button.point = point;
    button.userID = [FirebaseHelper sharedHelper].uid;
    [button generateIdenticon];
    button.frame = CGRectMake(0, 0, button.userImage.size.width, button.userImage.size.height);
    button.center = CGPointMake(point.x-40, point.y+22);
    CGAffineTransform tr = CGAffineTransformScale(button.transform, .25, .25);
    tr = CGAffineTransformRotate(tr, -M_PI_2);
    button.transform = tr;
    [button addTarget:self action:@selector(commentTapped:) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(commentLongPress:)];
    longPress.minimumPressDuration = .2;
    [button addGestureRecognizer:longPress];
    
    [self addSubview:button];
    
    [self.commentButtons addObject:button];
    
    [self commentTapped:button];
    
}

-(void) commentLongPress:(UILongPressGestureRecognizer*)sender {
    
    CommentButton *button = (CommentButton *)sender.view;
    CGPoint point = [sender locationInView:self];
    
    CGPoint pointForTargetView = [button.deleteButton convertPoint:point fromView:self];
    if (CGRectContainsPoint(button.deleteButton.bounds, pointForTargetView)) return;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
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
                             
                             [self updateCarouselOffsetWithPoint:button.point];
                             
                             NSDictionary *locationDict = @{ @"x" : @(button.point.x), @"y" : @(button.point.y) };
                             
                             NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"commentsID"];
                             
                             [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:button.commentThreadID] setObject:[locationDict mutableCopy] forKey:@"location"];
                             
                             NSString *locationString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/info/location", commentsID, button.commentThreadID];
                             Firebase *locationRef = [[Firebase alloc] initWithUrl:locationString];
                             [locationRef setValue:locationDict];
                             
                         }];
    }
}

-(BOOL) userDrawing {
    
    BOOL isDrawing = false;
    
    for (NSString *uid in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        if ([uid isEqualToString:[FirebaseHelper sharedHelper].uid]) continue;
        
        if ([[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:uid] objectForKey:@"inBoard"] isEqualToString:self.boardID] && [[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:uid] objectForKey:@"isDrawing"] integerValue] > 0) {
            
            isDrawing = true;
        }
    }
    
    return isDrawing;
}

-(void) addUserDrawing {
    
    for (AvatarButton *avatar in self.avatarButtons) {
        
        if ([avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) avatar.drawingImage.hidden = false;
    }
    
    [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@1 forKey:@"isDrawing"];
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", [FirebaseHelper sharedHelper].uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    [[ref childByAppendingPath:@"isDrawing"] setValue:@1];
}

-(void) removeUserDrawing {
    
    for (AvatarButton *avatar in self.avatarButtons) {
        
        if ([avatar.userID isEqualToString:[FirebaseHelper sharedHelper].uid]) avatar.drawingImage.hidden = true;
    }
    
    [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@0 forKey:@"isDrawing"];
    NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@", [FirebaseHelper sharedHelper].uid];
    Firebase *ref = [[Firebase alloc] initWithUrl:teamString];
    [[ref childByAppendingPath:@"isDrawing"] setValue:@0];
}

-(void) avatarTapped:(id)sender {
    
    AvatarButton *avatar = (AvatarButton *)sender;
    
    if([[[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"roles"] objectForKey:avatar.userID] integerValue] == 0) return;
    
    for (AvatarButton *avtr in self.avatarButtons) {
        avtr.highlightedImage.hidden = true;
    }
    
    if  ([avatar.userID isEqualToString:self.selectedAvatarUserID])
        self.selectedAvatarUserID = nil;
    else {
        avatar.highlightedImage.hidden = false;
        self.selectedAvatarUserID = avatar.userID;
    }
    
    [projectVC drawBoard:self];
}

-(void) commentTapped:(id)sender {
    
    CommentButton *comment = (CommentButton *)sender;
    
    [projectVC.viewedCommentThreadIDs addObject:comment.commentThreadID];
    projectVC.erasing = false;
    
    for (int i=5; i<=8; i++) {
        
        if (i==7) continue;
        
        UIView *button = [projectVC.view viewWithTag:i];
        if (i==8) [button viewWithTag:50].hidden = false;
        else [button viewWithTag:50].hidden = true;
    }
    
    for (CommentButton *commentButton in self.commentButtons) {
        
        commentButton.deleteButton.hidden = true;
        commentButton.commentImage.hidden = false;
        commentButton.highlightedImage.hidden = true;
    }
    
    [self updateCarouselOffsetWithPoint:comment.point];
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"commentsID"];
    NSString *ownerID = [[[[FirebaseHelper sharedHelper].comments objectForKey:commentsID] objectForKey:comment.commentThreadID] objectForKey:@"owner"];
    
    if ([ownerID isEqualToString:[FirebaseHelper sharedHelper].uid]) comment.deleteButton.hidden = false;
    comment.commentImage.hidden = true;
    comment.highlightedImage.hidden = false;
    
    projectVC.activeCommentThreadID = comment.commentThreadID;
    
    [projectVC updateMessages];
    [projectVC.chatTable reloadData];
    
    [projectVC.chatTextField becomeFirstResponder];
}

-(void) updateCarouselOffsetWithPoint:(CGPoint)point {
    
    float oldOffset = projectVC.carouselOffset;
    projectVC.carouselOffset = (point.x*.75)-70;
    
    if ([projectVC.chatTextField isFirstResponder] && projectVC.carouselOffset > 0) {
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:.25];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        CGRect carouselRect = projectVC.carousel.frame;
        carouselRect.origin.y += (oldOffset - projectVC.carouselOffset);
        projectVC.carousel.frame = carouselRect;
        
        CGRect backgroundRect = self.avatarBackgroundImage.frame;
        backgroundRect.origin.x -= (oldOffset - projectVC.carouselOffset);
        self.avatarBackgroundImage.frame = backgroundRect;

        for (AvatarButton *avatar in self.avatarButtons) {
            
            CGRect avatarRect = avatar.frame;
            avatarRect.origin.x -= (oldOffset - projectVC.carouselOffset);
            avatar.frame = avatarRect;
        }
        
        [UIView commitAnimations];
    }
}

#pragma mark interface

-(void)clear {
    
    
    
    self.paths = [NSMutableArray array];
    [self setNeedsDisplay];
}

@end
