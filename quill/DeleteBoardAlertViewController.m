//
//  DeleteBoardAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 5/18/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "DeleteBoardAlertViewController.h"
#import "FirebaseHelper.h"
#import "ProjectDetailViewController.h"

@implementation DeleteBoardAlertViewController

-(void) viewDidLoad {
    
    [super viewDidLoad];
    
    projectVC = [FirebaseHelper sharedHelper].projectVC;
    
    self.navigationItem.title = @"Delete Board";
    
    self.deleteButton.layer.borderWidth = 1;
    self.deleteButton.layer.cornerRadius = 10;
    self.deleteButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void) viewWillAppear:(BOOL)animated {
    
    NSString *boardName;
    
    if ([FirebaseHelper sharedHelper].projectVC.versioning) {
        
        NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:[FirebaseHelper sharedHelper].projectVC.boardIDs[[FirebaseHelper sharedHelper].projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
        NSString *boardID = versionsArray[[FirebaseHelper sharedHelper].projectVC.versionsCarousel.currentItemIndex];
        
        boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"name"];
    }
    else {
        
        NSString *boardID = [FirebaseHelper sharedHelper].projectVC.boardIDs[[FirebaseHelper sharedHelper].projectVC.carousel.currentItemIndex];
        
        boardName = [[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"name"];
    }
    
    UIFont *regFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    UIFont *boardFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    
    NSDictionary *regAttrs = [NSDictionary dictionaryWithObjectsAndKeys: regFont, NSFontAttributeName, nil];
    NSDictionary *boardAttrs = [NSDictionary dictionaryWithObjectsAndKeys: boardFont, NSFontAttributeName, nil];
    
    NSString *boardString;
    int boldLength;
    
    if (projectVC.versioning && projectVC.versionsCarousel.currentItemIndex > 0) {
        boardString = [NSString stringWithFormat:@"Are you sure you want to delete Version %i of %@?", projectVC.versionsCarousel.currentItemIndex+1, boardName];
        boldLength = boardName.length+12+[@(projectVC.versionsCarousel.currentItemIndex+1) stringValue].length;
    }
    else {
        boardString = [NSString stringWithFormat:@"Are you sure you want to delete %@?", boardName];
        boldLength = boardName.length;
    }
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:boardString attributes:regAttrs];
    [attrString setAttributes:boardAttrs range:NSMakeRange(32, boldLength)];
    
    [self.boardLabel setAttributedText:attrString];
}

-(void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) viewWillDisappear:(BOOL)animated {
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)deleteTapped:(id)sender {


    NSString *boardID = [FirebaseHelper sharedHelper].projectVC.boardIDs[[FirebaseHelper sharedHelper].projectVC.carousel.currentItemIndex];
    NSMutableArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:[FirebaseHelper sharedHelper].projectVC.boardIDs[[FirebaseHelper sharedHelper].projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
    
    if (projectVC.versioning && projectVC.versionsCarousel.currentItemIndex > 0) {
        
        NSString *versionBoardID = versionsArray[projectVC.versionsCarousel.currentItemIndex];
        [versionsArray removeObject:versionBoardID];
        
        NSString *boardString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/versions", [FirebaseHelper sharedHelper].db, boardID];
        Firebase *boardRef = [[Firebase alloc] initWithUrl:boardString];
        [boardRef setValue:versionsArray];
        
        [projectVC deleteBoardWithID:versionBoardID];
        
        projectVC.upArrowImage.hidden = true;
        projectVC.downArrowImage.hidden = true;
        [projectVC.versionsCarousel reloadData];
        
        NSString *labelString = [NSString stringWithFormat:@"Version %i of", projectVC.versionsCarousel.currentItemIndex+1];
        projectVC.versionsLabel.text = labelString;
    }
    else {
        
        [projectVC.boardIDs removeObject:boardID];
        
        NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/boards", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [projectRef setValue:projectVC.boardIDs];
        
        [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"boards"] removeObject:boardID];
        
        [projectVC deleteBoardWithID:boardID];
        
        for (int i=1; i<versionsArray.count; i++) [projectVC deleteBoardWithID:versionsArray[i]];
        
        if (projectVC.versioning) [projectVC versionsTapped:nil];
        if (projectVC.boardIDs.count == 0) [projectVC createBoard];
    }
    
    [projectVC.carousel reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
