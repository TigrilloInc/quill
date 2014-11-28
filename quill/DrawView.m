//
//  DrawView.m
//  Quill
//
//  Created by Alex Costantini on 7/2/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//


#import "DrawView.h"

#import <QuartzCore/QuartzCore.h>

#import "FirebaseHelper.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "ProjectDetailViewController.h"
#import "NSDate+ServerDate.h"
#import "AvatarButton.h"

#define DEFAULT_COLOR               [UIColor blackColor]
#define DEFAULT_WIDTH               2.0f
#define DEFAULT_BACKGROUND_COLOR    [UIColor whiteColor]

static const CGFloat kPointMinDistance = 2.0f;
static const CGFloat kPointMinDistanceSquared = kPointMinDistance * kPointMinDistance;

@interface DrawView ()
@property (nonatomic,assign) CGPoint currentPoint;
@property (nonatomic,assign) CGPoint previousPoint;
@property (nonatomic,assign) CGPoint previousPreviousPoint;

#pragma mark Private Helper function
CGPoint midPoint(CGPoint p1, CGPoint p2);
@end

@implementation DrawView {
@private
    
    NSMutableArray *_paths;
    ProjectDetailViewController *projectVC;
}

#pragma mark UIView lifecycle methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        //self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
        _paths = [NSMutableArray array];
        _lineWidth = DEFAULT_WIDTH;
        self.lineColorNumber = @1;
        _empty = YES;
        self.activeUserIDs = [NSMutableArray array];
        
        projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;;
        
        if (projectVC.userRole > 0) self.drawable = true;
        else self.drawable = false;
        
        self.selectedAvatarUserID = nil;
        
    }
    
    return self;
}

- (void) layoutAvatars {
    
    for (AvatarButton *avatar in self.avatarButtons) [avatar removeFromSuperview];
    
    self.avatarButtons = [NSMutableArray array];
    
    NSMutableArray *unsortedUserIDs = [self.activeUserIDs mutableCopy];
    
    if ([projectVC.activeBoardID isEqualToString:self.boardID]) {
        
        NSDictionary *userPaths = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"allSubpaths"];
        
        for (NSString *userID in userPaths.allKeys) {
            
            if (![unsortedUserIDs containsObject:userID] && ((NSDictionary *)[userPaths objectForKey:userID]).allKeys.count > 1) [unsortedUserIDs addObject:userID];
        }
    }
    
    NSArray *userIDs = [unsortedUserIDs sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (int i=0; i<userIDs.count; i++) {
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userIDs[i];
        avatar.frame = CGRectMake(-50, (i-1)*64, avatar.userImage.size.width, avatar.userImage.size.height);
        CGAffineTransform tr = CGAffineTransformScale(avatar.transform, .25, .25);
        tr = CGAffineTransformRotate(tr, -M_PI_2);
        avatar.transform = tr;
        NSNumber *imageNumber = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"avatar"];
        NSString *imageString = [NSString stringWithFormat:@"user%@.png", imageNumber];
        [avatar setImage:[UIImage imageNamed:imageString] forState:UIControlStateNormal];
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

    for (NSString *commentThreadID in commentDict.allKeys) {
        
        CommentButton *button = [CommentButton buttonWithType:UIButtonTypeCustom];
        button.commentThreadID = commentThreadID;
        float x = [[[[commentDict objectForKey:commentThreadID] objectForKey:@"location"] objectForKey:@"x"] floatValue];
        float y = [[[[commentDict objectForKey:commentThreadID] objectForKey:@"location"] objectForKey:@"y"] floatValue];
        button.point = CGPointMake(x, y);
        button.frame = CGRectMake(0, 0, button.userImage.size.width, button.userImage.size.height);
        button.center = CGPointMake(button.point.x-40, button.point.y+40);
        CGAffineTransform tr = CGAffineTransformScale(button.transform, .25, .25);
        tr = CGAffineTransformRotate(tr, -M_PI_2);
        button.transform = tr;
        [button addTarget:self action:@selector(commentTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        NSString *ownerID = [[commentDict objectForKey:commentThreadID] objectForKey:@"owner"];

        NSNumber *imageNumber = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:ownerID] objectForKey:@"avatar"];
        NSString *imageString = [NSString stringWithFormat:@"user%@.png", imageNumber];
        if(imageNumber != nil)[button setImage:[UIImage imageNamed:imageString] forState:UIControlStateNormal];
        
        if ([ownerID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(commentLongPress:)];
            longPress.minimumPressDuration = .2;
            [button addGestureRecognizer:longPress];
        }
        
        if ([commentThreadID isEqualToString:projectVC.activeCommentThreadID]) {
            
            button.commentImage.hidden = true;
            button.highlightedImage.hidden = false;
            button.deleteButton.hidden = false;
        }
        
        [self addSubview:button];
        [self.commentButtons addObject:button];
    }
    
    [self bringSubviewToFront:[self viewWithTag:2]];
}

- (void)drawRect:(CGRect)rect {
    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);
    
    // get the graphics context and draw the path
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    
    for (NSDictionary *subpathValues in _paths) {
        
        CGMutablePathRef subpath = CGPathCreateMutable();
        CGPathMoveToPoint(subpath, NULL, [[subpathValues objectForKey:@"mid1x"] floatValue], [[subpathValues objectForKey:@"mid1y"] floatValue]);
        CGPathAddQuadCurveToPoint(subpath, NULL,
                                  [[subpathValues objectForKey:@"prevx"] floatValue], [[subpathValues objectForKey:@"prevy"] floatValue],
                                  [[subpathValues objectForKey:@"mid2x"] floatValue], [[subpathValues objectForKey:@"mid2y"] floatValue]);
        CGContextAddPath(context, subpath);
        
        int colorNumber = [[subpathValues objectForKey:@"color"] intValue];
        UIColor *lineColor;
        
        if (colorNumber == 0) lineColor = [UIColor whiteColor];
        if (colorNumber == 1) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(220.0f/255.0f) green:(220.0f/255.0f) blue:(220.0f/255.0f) alpha:1.0f];
            else lineColor = [UIColor blackColor];
        }
        if (colorNumber == 2) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(200.0f/255.0f) green:(230.0f/255.0f) blue:1.0f alpha:1.0f];
            else lineColor = [UIColor colorWithRed:0.0f green:(60.0f/255.0f) blue:1.0f alpha:1.0f];
        }
        if (colorNumber == 3) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:1.0f green:(200.0f/255.0f) blue:(200.0f/255.0f) alpha:1.0f];
            else lineColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f];
        }
        if (colorNumber == 4) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(230.0f/255.0f) green:1.0f blue:(200.0f/255.0f) alpha:1.0f];
            else lineColor = [UIColor colorWithRed:(60.0f/255.0f) green:1.0f blue:0.0f alpha:1.0f];
        }
        
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextSetLineWidth(context, [[subpathValues objectForKey:@"width"] floatValue]);
        CGContextStrokePath(context);
        CGContextBeginPath(context);
    }
    
    self.empty = NO;
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
    
    // compute the rect containing the new segment plus padding for drawn line
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * self.lineWidth, -2.0 * self.lineWidth);
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    NSDictionary *subpathValues =  @{ @"mid1x" : @(self.currentPoint.x),
                                      @"mid1y" : @(self.currentPoint.y),
                                      @"mid2x" : @(self.currentPoint.x),
                                      @"mid2y" : @(self.currentPoint.y),
                                      @"prevx" : @(self.currentPoint.x),
                                      @"prevy" : @(self.currentPoint.y),
                                      @"color" : self.lineColorNumber,
                                      @"width" : @(self.lineWidth)
                                      };
    
    [_paths addObject:subpathValues];
    
    [self setNeedsDisplayInRect:drawBox];
    
    NSString *allSubpathsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/allSubpaths/%@", self.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *allSubpathsRef = [[Firebase alloc] initWithUrl:allSubpathsString];
    NSString *lastSubpathString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/lastSubpath", self.boardID];
    Firebase *lastSubpathRef = [[Firebase alloc] initWithUrl:lastSubpathString];
    
    [allSubpathsRef updateChildValues:@{ dateString  :  subpathValues }];
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"allSubpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
    
    NSMutableDictionary *lastSubpathDict = [subpathValues mutableCopy];
    [lastSubpathDict setObject:[FirebaseHelper sharedHelper].uid forKey:@"uid"];
    [lastSubpathRef setValue:lastSubpathDict];
    
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
    
    if ((dx * dx + dy * dy) < kPointMinDistanceSquared) {
        // ... then ignore this movement
        return;
    }
    
    // update points: previousPrevious -> mid1 -> previous -> mid2 -> current
    self.previousPreviousPoint = self.previousPoint;
    self.previousPoint = [touch previousLocationInView:self];
    self.currentPoint = [touch locationInView:self];
    
    CGPoint mid1 = midPoint(self.previousPoint, self.previousPreviousPoint);
    CGPoint mid2 = midPoint(self.currentPoint, self.previousPoint);
    
    // to represent the finger movement, create a new path segment,
    // a quadratic bezier path from mid1 to mid2, using previous as a control point
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL,
                              self.previousPoint.x, self.previousPoint.y,
                              mid2.x, mid2.y);
    
    // compute the rect containing the new segment plus padding for drawn line
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * self.lineWidth, -2.0 * self.lineWidth);
    
    NSDictionary *subpathValues =  @{ @"mid1x" : @(mid1.x),
                                      @"mid1y" : @(mid1.y),
                                      @"mid2x" : @(mid2.x),
                                      @"mid2y" : @(mid2.y),
                                      @"prevx" : @(self.previousPoint.x),
                                      @"prevy" : @(self.previousPoint.y),
                                      @"color" : self.lineColorNumber,
                                      @"width" : @(self.lineWidth)
                                      };
    
    [_paths addObject:subpathValues];
    
    [self setNeedsDisplayInRect:drawBox];
    
    NSString *allSubpathsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/allSubpaths/%@", self.boardID, [FirebaseHelper sharedHelper].uid];
    Firebase *allSubpathsRef = [[Firebase alloc] initWithUrl:allSubpathsString];
    NSString *lastSubpathString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/lastSubpath", self.boardID];
    Firebase *lastSubpathRef = [[Firebase alloc] initWithUrl:lastSubpathString];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    [allSubpathsRef updateChildValues:@{ dateString  :  subpathValues }];
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"allSubpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:subpathValues forKey:dateString];
    
    NSMutableDictionary *lastSubpathDict = [subpathValues mutableCopy];
    [lastSubpathDict setObject:[FirebaseHelper sharedHelper].uid forKey:@"uid"];
    [lastSubpathRef setValue:lastSubpathDict];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.drawable) return;
    
    if (self.commenting) {
        
        self.commenting = false;
        return;
    }
    
    if ([projectVC.chatTextField isFirstResponder]) {
        
        [self hideChat];
        return;
    }
    
    [self performSelector:@selector(removeUserDrawing) withObject:nil afterDelay:1.0];
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    NSString *boardString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@", self.boardID];
    Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
    
    NSDictionary *penUpDict = @{ dateString  :  @"penUp" };
    NSString *allSubpathsString = [NSString stringWithFormat:@"allSubpaths/%@", [FirebaseHelper sharedHelper].uid];
    [[boardRef childByAppendingPath:allSubpathsString] updateChildValues:penUpDict];
    
    NSMutableDictionary *undoDict = [[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"undo"] objectForKey:[FirebaseHelper sharedHelper].uid];
    
    int undoTotal = [[undoDict objectForKey:@"total"] intValue];
    undoTotal++;
    [undoDict setObject:@(undoTotal) forKey:@"total"];
    
    NSDictionary *newUndoDict = @{  @"currentIndex" : @0,
                                    @"currentIndexDate" : dateString,
                                    @"total" : @(undoTotal)
                                    };
    
    NSString *undoString = [NSString stringWithFormat:@"undo/%@", [FirebaseHelper sharedHelper].uid];
    [[boardRef childByAppendingPath:undoString] setValue:newUndoDict];
    
    [[boardRef childByAppendingPath:@"lastSubpath"] setValue:@{ @"penUp" : [FirebaseHelper sharedHelper].uid }];
    
    [[[[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"allSubpaths"] objectForKey:[FirebaseHelper sharedHelper].uid] setObject:@"penUp" forKey:dateString];
    
    [[FirebaseHelper sharedHelper] setProjectUpdatedAt];
    [[FirebaseHelper sharedHelper] setActiveBoardUpdatedAt];
}

-(void) drawSubpath:(NSDictionary *)subpathValues {
    
    if (subpathValues.allValues.count < 8) return;
    
    CGPoint mid1;
    CGPoint mid2;
    CGPoint prev;
    
    mid1.x = [[subpathValues objectForKey:@"mid1x"] floatValue];
    mid1.y = [[subpathValues objectForKey:@"mid1y"] floatValue];
    mid2.x = [[subpathValues objectForKey:@"mid2x"] floatValue];
    mid2.y = [[subpathValues objectForKey:@"mid2y"] floatValue];
    prev.x = [[subpathValues objectForKey:@"prevx"] floatValue];
    prev.y = [[subpathValues objectForKey:@"prevy"] floatValue];
    
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL,
                              prev.x, prev.y,
                              mid2.x, mid2.y);
    
    CGRect bounds = CGPathGetBoundingBox(subpath);
    CGRect drawBox = CGRectInset(bounds, -2.0 * self.lineWidth, -2.0 * self.lineWidth);
    
    [_paths addObject:subpathValues];
    
    [self setNeedsDisplayInRect:drawBox];
    
}

-(void) hideChat {
    
    [projectVC.chatTextField resignFirstResponder];
    [projectVC.view bringSubviewToFront:projectVC.carousel];
    [projectVC showDrawMenu];
    projectVC.carouselOffset = 0;
    
    for (CommentButton *commentButton in self.commentButtons) {
        
        commentButton.commentImage.hidden = false;
        commentButton.highlightedImage.hidden = true;
        commentButton.deleteButton.hidden = true;
    }
}

-(void) addCommentAtPoint:(CGPoint)point {
    
    NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:projectVC.activeBoardID] objectForKey:@"commentsID"];
    
    NSDictionary *commentDict = @{ @"location" : @{ @"x" : @(point.x),
                                                    @"y" : @(point.y)
                                                    },
                                   @"owner" : [FirebaseHelper sharedHelper].uid
                                   };
    
    NSString *commentThreadString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@", commentsID];
    Firebase *commentThreadRef = [[Firebase alloc] initWithUrl:commentThreadString];
    
    Firebase *commentThreadRefWithID = [commentThreadRef childByAutoId];
    [commentThreadRefWithID setValue:commentDict withCompletionBlock:^(NSError *error, Firebase *ref) {
        [[FirebaseHelper sharedHelper] setProjectUpdatedAt];
    }];
    
    CommentButton *button = [CommentButton buttonWithType:UIButtonTypeCustom];
    button.commentThreadID = commentThreadRefWithID.name;
    button.point = point;
    NSNumber *imageNumber = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"avatar"];
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"user%@.png", imageNumber]];
    if(imageNumber != nil)[button setImage:image forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    button.center = CGPointMake(point.x-40, point.y+40);
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
                         }
         
                         completion:^(BOOL finished) {

                             button.center = CGPointMake(MAX(0,MIN(button.center.x,768)), MAX(0,MIN(button.center.y,1024)));
                             
                             button.point = CGPointMake(MAX(0,MIN(button.center.x,768))+40, button.center.y-40);
                             
                             [self updateCarouselOffsetWithPoint:button.point];
                             
                             NSString *commentsID = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardID] objectForKey:@"commentsID"];
                             NSString *locationString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/comments/%@/%@/location", commentsID, button.commentThreadID];
                             Firebase *locationRef = [[Firebase alloc] initWithUrl:locationString];
                             
                             [locationRef setValue:@{ @"x" : @(button.point.x), @"y" : @(button.point.y) }];
                             
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
    
    _paths = [NSMutableArray array];
    [self setNeedsDisplay];
}

@end
