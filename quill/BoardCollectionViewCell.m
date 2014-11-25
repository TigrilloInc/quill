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
        
        self.drawView = [[DrawView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
        self.drawView.drawable = false;
        CGAffineTransform tr = self.drawView.transform;
        tr = CGAffineTransformScale(tr, .1875, .1875);
        tr = CGAffineTransformTranslate(tr, -1536, -2348);
        tr = CGAffineTransformRotate(tr, M_PI_2);
        self.drawView.transform = tr;
        [self.contentView addSubview:self.drawView];
        
        UIImage *deleteImage = [UIImage imageNamed:@"close.png"];
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton.frame = CGRectMake(-deleteImage.size.width/2, -deleteImage.size.height/2, deleteImage.size.width, deleteImage.size.height);
        [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.deleteButton];
        [self bringSubviewToFront:self.deleteButton];
    }
    return self;
}

-(void) updateSubpathsForBoardID:(NSString *)boardID {
    
    [self.drawView clear];
    
    NSDictionary *allSubpathsDict = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"allSubpaths"];
    
    NSDictionary *dictRef = [[[FirebaseHelper sharedHelper].boards objectForKey:self.drawView.boardID] objectForKey:@"undo"];
    NSMutableDictionary *undoDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)dictRef, kCFPropertyListMutableContainers));
    
    NSMutableDictionary *subpathsToDraw = [NSMutableDictionary dictionary];
    
    for (NSString *uid in allSubpathsDict.allKeys) {
        
        NSDictionary *uidDict = [allSubpathsDict objectForKey:uid];
        
        NSMutableArray *userOrderedKeys = [uidDict.allKeys mutableCopy];
        NSSortDescriptor *descendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        [userOrderedKeys sortUsingDescriptors:@[descendingSorter]];
        
        BOOL undone = false;
        
        for (int i=0; i<userOrderedKeys.count; i++) {
            
            NSDictionary *subpathValues = (NSDictionary *)[uidDict objectForKey:(NSString *)userOrderedKeys[i]];
            
            if ([subpathValues respondsToSelector:@selector(objectForKey:)]){
                
                if (!undone) {
                    
                    [subpathsToDraw setObject:subpathValues forKey:userOrderedKeys[i]];
                    //[drawView drawSubpath:subpathValues];
                }
                
            } else {
                
                int undoCount = [(NSNumber *)[[undoDict objectForKey:uid] objectForKey:@"currentIndex"] intValue];
                
                if (undoCount > 0) {
                    
                    undone = true;
                    undoCount--;

                    [[undoDict objectForKey:uid] setObject:@(undoCount) forKey:@"currentIndex"];
                    
                } else {
                    
                    ////THERE'S SOME MISSING LOGIC THAT SHOULD GO HERE
                    
                    undone = false;
                }
            }
        }
    }
    
    NSMutableArray *allOrderedKeys = [subpathsToDraw.allKeys mutableCopy];
    NSSortDescriptor *ascendingSorter = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [allOrderedKeys sortUsingDescriptors:@[ascendingSorter]];
    
    for (int i=0; i<allOrderedKeys.count; i++) {
        
        NSDictionary *subpathDict = [subpathsToDraw objectForKey:allOrderedKeys[i]];
        [self.drawView drawSubpath:subpathDict];

    }
}

-(void)deleteTapped {
 
    ProjectDetailViewController *projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    [projectVC.editBoardIDs removeObject:self.drawView.boardID];
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
