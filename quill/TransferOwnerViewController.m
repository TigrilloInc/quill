//
//  TransferOwnerViewController.m
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "TransferOwnerViewController.h"
#import "FirebaseHelper.h"

@implementation TransferOwnerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Transfer Ownership";
    
    self.ownerButton.layer.borderWidth = 1;
    self.ownerButton.layer.cornerRadius = 10;
    self.ownerButton.layer.borderColor = [UIColor grayColor].CGColor;
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.cornerRadius = 10;
    self.cancelButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    NSMutableDictionary *usersDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)[[FirebaseHelper sharedHelper].team objectForKey:@"users"], kCFPropertyListMutableContainers));
    for (NSString *userID in usersDict.allKeys) {
        
        if ([projectVC.roles.allKeys containsObject:userID]) [usersDict removeObjectForKey:userID];
    }
    self.availableUsersDict = usersDict;
}

-(void) viewWillAppear:(BOOL)animated {
    
    NSString *projectName = [[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"name"];
    
    UIFont *regFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    UIFont *projectFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:17];
    
    NSDictionary *regAttrs = [NSDictionary dictionaryWithObjectsAndKeys: regFont, NSFontAttributeName, nil];
    NSDictionary *projectAttrs = [NSDictionary dictionaryWithObjectsAndKeys: projectFont, NSFontAttributeName, nil];
    NSRange projectRange = NSMakeRange(23, projectName.length);
    
    NSString *projectString = [NSString stringWithFormat:@"Select a new owner for %@ before leaving.", projectName];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:projectString attributes:regAttrs];
    [attrString setAttributes:projectAttrs range:projectRange];
    
    [self.ownerLabel setAttributedText:attrString];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.availableUsersDict.allKeys.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 48.0;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (int i=1; i<4; i++) {
        
        if ([cell.contentView viewWithTag:400+i] != nil) [[cell.contentView viewWithTag:400+i] removeFromSuperview];
    }
    
    NSString *userID = self.availableUsersDict.allKeys[indexPath.row];
    
    UILabel *userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 11, 0, 0)];
    userNameLabel.text = [[self.availableUsersDict objectForKey:userID] objectForKey:@"name"];
    userNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
    [userNameLabel sizeToFit];
    userNameLabel.tag = 401;
    [cell.contentView addSubview:userNameLabel];
    
    AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
    avatar.userID = userID;
    [avatar generateIdenticonWithShadow:false];
    avatar.frame = CGRectMake(-93, -99.5, avatar.userImage.size.width, avatar.userImage.size.height);
    avatar.transform = CGAffineTransformMakeScale(.16, .16);
    avatar.tag = 402;
    avatar.userInteractionEnabled = false;
    [cell.contentView addSubview:avatar];
    
    UIImageView *checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(370, 6, 35, 35)];
    checkImageView.tag = 403;
    [cell.contentView addSubview:checkImageView];
    
    if ([self.selectedUserID isEqualToString:userID]) {
        
        checkImageView.image = [UIImage imageNamed:@"checked.png"];
        checkImageView.alpha = 1;
        avatar.alpha = 1;
        userNameLabel.alpha = 1;
    }
    else {
        
        checkImageView.image = [UIImage imageNamed:@"unchecked.png"];
        checkImageView.alpha = .3;
        avatar.alpha = .3;
        userNameLabel.alpha = .3;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.selectedUserID = self.availableUsersDict.allKeys[indexPath.row];
    [tableView reloadData];
}


@end
