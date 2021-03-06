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
    
    self.deleteButton.layer.borderWidth = 1;
    self.deleteButton.layer.cornerRadius = 10;
    self.deleteButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void) viewWillAppear:(BOOL)animated {
    
    NSString *boardName;
    
    NSArray *versionsArray = [[[FirebaseHelper sharedHelper].boards objectForKey:[FirebaseHelper sharedHelper].projectVC.boardIDs[[FirebaseHelper sharedHelper].projectVC.carousel.currentItemIndex]] objectForKey:@"versions"];
    
    if ([FirebaseHelper sharedHelper].projectVC.versioning) {
        
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
        
        boardString = [NSString stringWithFormat:@"Are you sure you want to delete Version %lu of %@?", projectVC.versionsCarousel.currentItemIndex+1, boardName];
        boldLength = boardName.length+12+[@(projectVC.versionsCarousel.currentItemIndex+1) stringValue].length;
        
        self.recoverLabel.text = @"Deleted versions of a board cannot be recovered.";
        self.navigationItem.title = @"Delete Version";
        [self.deleteButton setTitle:@"Delete Version" forState:UIControlStateNormal];
        
        UIImageView *logoImageView = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
        logoImageView.frame = CGRectMake(172, 8, 32, 32);
    }
    else {
        
        if (versionsArray.count > 1) boardString = [NSString stringWithFormat:@"Are you sure you want to delete %@?\nAll of its versions (%lu) will also be deleted.", boardName, versionsArray.count-1];
        else boardString = [NSString stringWithFormat:@"Are you sure you want to delete %@?", boardName];
        
        boldLength = boardName.length;
        
        self.recoverLabel.text = @"Deleted boards cannot be recovered.";
        self.navigationItem.title = @"Delete Board";
        [self.deleteButton setTitle:@"Delete Board" forState:UIControlStateNormal];
    }
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:boardString attributes:regAttrs];
    [attrString setAttributes:boardAttrs range:NSMakeRange(32, boldLength)];
    
    [self.boardLabel setAttributedText:attrString];
}

-(void) viewDidAppear:(BOOL)animated {
    
    projectVC.handleOutsideTaps = true;
}

-(void) viewWillDisappear:(BOOL)animated {
    
    projectVC.handleOutsideTaps = false;
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
        
        if (projectVC.versionsCarousel.currentItemIndex == 0) {
            
            if (versionsArray.count > 1) projectVC.versionsLabel.text = [NSString stringWithFormat:@"Original (Version 1 of %lu)", versionsArray.count];
            else projectVC.versionsLabel.text = @"Original (Version 1)";

        }
        else projectVC.versionsLabel.text = [NSString stringWithFormat:@"Version %lu of %lu", projectVC.versionsCarousel.currentItemIndex+1, versionsArray.count];

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

@end
