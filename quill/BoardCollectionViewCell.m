//
//  BoardCollectionViewCell.m
//  Quill
//
//  Created by Alex Costantini on 8/19/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "BoardCollectionViewCell.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"

@implementation BoardCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.clipsToBounds = false;
        
        self.boardView = [[BoardView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
        self.boardView.drawable = false;
        CGAffineTransform tr = self.boardView.transform;
        tr = CGAffineTransformScale(tr, .1875, .1875);
        //tr = CGAffineTransformTranslate(tr, -1536, -2348);
        tr = CGAffineTransformRotate(tr, M_PI_2);
        self.boardView.transform = tr;
        self.boardView.center = self.center;
        [self.contentView addSubview:self.boardView];
        
        self.gradientImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"board7.png"]];
        self.gradientImage.center = self.center;
        self.gradientImage.transform = tr;
        [self.contentView addSubview:self.gradientImage];
        
        self.boardNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1024, 20)];
        self.boardNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:18];
        [self.contentView addSubview:self.boardNameLabel];
        
        UIImage *deleteImage = [UIImage imageNamed:@"close.png"];
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton.frame = CGRectMake(-deleteImage.size.width/2, -deleteImage.size.height/2, deleteImage.size.width, deleteImage.size.height);
        self.deleteButton.transform = CGAffineTransformMakeScale(.1, .1);
        [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.deleteButton];
        [self bringSubviewToFront:self.deleteButton];
    }
    return self;
}

-(void) updateSubpathsForBoardID:(NSString *)boardID {
    
    [self.boardView clear];
    
    NSDictionary *subpathsDict = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"subpaths"];
    
    NSDictionary *dictRef = [[[FirebaseHelper sharedHelper].boards objectForKey:self.boardView.boardID] objectForKey:@"undo"];
    NSMutableDictionary *undoDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)dictRef, kCFPropertyListMutableContainers));
    
    NSMutableDictionary *subpathsToDraw = [NSMutableDictionary dictionary];
    
    for (NSString *uid in subpathsDict.allKeys) {
        
        NSDictionary *uidDict = [subpathsDict objectForKey:uid];
        
        NSMutableArray *userOrderedKeys = [uidDict.allKeys mutableCopy];
        NSSortDescriptor *descendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [userOrderedKeys sortUsingDescriptors:@[descendingSorter]];
        
        BOOL undone = false;
        BOOL cleared = false;
        int undoCount = [[[undoDict objectForKey:uid] objectForKey:@"currentIndex"] intValue];
        
        for (int i=0; i<userOrderedKeys.count; i++) {
            
            NSDictionary *subpathValues = (NSDictionary *)[uidDict objectForKey:(NSString *)userOrderedKeys[i]];
            
            if ([subpathValues respondsToSelector:@selector(objectForKey:)]){
                
                if (!undone && !cleared) [subpathsToDraw setObject:subpathValues forKey:userOrderedKeys[i]];
                
            }
            
            else if ([[uidDict objectForKey:userOrderedKeys[i]] respondsToSelector:@selector(isEqualToString:)]) {
                
                if ([[uidDict objectForKey:userOrderedKeys[i]] isEqualToString:@"penUp"]) {
                    
                    [subpathsToDraw setObject:@{userOrderedKeys[i] : @"penUp"} forKey:userOrderedKeys[i]];
                    
                    if (undoCount > 0) {
                        
                        undone = true;
                        undoCount--;
                    }
                    else undone = false;
                    
                }
                
                else if ([[uidDict objectForKey:userOrderedKeys[i]] isEqualToString:@"clear"] && !undone) cleared = true;
            }
        }
    }
    
    NSMutableArray *allOrderedKeys = [subpathsToDraw.allKeys mutableCopy];
    NSSortDescriptor *ascendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [allOrderedKeys sortUsingDescriptors:@[ascendingSorter]];
    
    for (int i=0; i<allOrderedKeys.count; i++) {
        
        NSDictionary *subpathDict = [subpathsToDraw objectForKey:allOrderedKeys[i]];
        [self.boardView drawSubpath:subpathDict];
    }
}

-(void) updateBoardNameForBoardID:(NSString *)boardID {
    
    self.boardNameLabel.text = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"name"];
    [self.boardNameLabel sizeToFit];
    self.boardNameLabel.center = CGPointMake(self.contentView.center.x,160);
    
}

-(void)deleteTapped {
 
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    [projectVC.editBoardIDs removeObject:self.boardView.boardID];
    [projectVC.draggableCollectionView reloadData];
    
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    CGPoint pointForTargetView = [self.deleteButton convertPoint:point fromView:self];
    
    if (CGRectContainsPoint(self.deleteButton.bounds, pointForTargetView)) {
        
        return [self.deleteButton hitTest:pointForTargetView withEvent:event];
    }
    
    return [super hitTest:point withEvent:event];
}

@end
