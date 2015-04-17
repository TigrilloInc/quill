//
//  TransferOwnerViewController.m
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "TransferOwnerViewController.h"
#import "FirebaseHelper.h"

@implementation TransferOwnerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Transfer Ownership";
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    self.ownerButton.layer.borderWidth = 1;
    self.ownerButton.layer.cornerRadius = 10;
    self.ownerButton.layer.borderColor = [UIColor grayColor].CGColor;

    NSMutableDictionary *usersDict = [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] mutableCopy];
    
    for (NSString *userID in usersDict.allKeys) {
        
        if (![projectVC.roles.allKeys containsObject:userID] || [userID isEqualToString:[FirebaseHelper sharedHelper].uid]) [usersDict removeObjectForKey:userID];
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

- (void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

- (IBAction)leaveTapped:(id)sender {

    if (self.selectedUserID == nil) return;
    
    NSString *leaveString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID, [FirebaseHelper sharedHelper].uid];
    Firebase *leaveRef = [[Firebase alloc] initWithUrl:leaveString];
    [leaveRef setValue:@(-1)];
    
    [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"roles"] setObject:@(-1) forKey:[FirebaseHelper sharedHelper].uid];
    [[FirebaseHelper sharedHelper].visibleProjectIDs removeObject:[FirebaseHelper sharedHelper].currentProjectID];
    
    NSString *ownerString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/roles/%@", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID, self.selectedUserID];
    Firebase *ownerRef = [[Firebase alloc] initWithUrl:ownerString];
    [ownerRef setValue:@(2)];
    
    [[[[FirebaseHelper sharedHelper].projects objectForKey:[FirebaseHelper sharedHelper].currentProjectID] objectForKey:@"roles"] setObject:@(2) forKey:self.selectedUserID];
    
    [FirebaseHelper sharedHelper].currentProjectID = nil;
    
    if ([FirebaseHelper sharedHelper].visibleProjectIDs.count == 0) [projectVC hideAll];
    else {
        NSIndexPath *mostRecent = [[FirebaseHelper sharedHelper] getLastViewedProjectIndexPath];
        [projectVC.masterView.projectsTable reloadData];
        [projectVC.masterView tableView:projectVC.masterView.projectsTable didSelectRowAtIndexPath:mostRecent];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
    }
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
    
    UIImage *avatarImage = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:avatar.userID] objectForKey:@"avatar"];
    
    if ([avatarImage isKindOfClass:[UIImage class]]) {
        
        [avatar setImage:avatarImage forState:UIControlStateNormal];
        avatar.imageView.layer.cornerRadius = avatarImage.size.width/2;
        avatar.imageView.layer.masksToBounds = YES;
        
        if (avatarImage.size.height == 64) {
            avatar.frame = CGRectMake(0, -8, avatarImage.size.width, avatarImage.size.height);
            avatar.transform = CGAffineTransformMakeScale(.56, .56);
        }
        else {
            avatar.frame = CGRectMake(-32, -40, avatarImage.size.width, avatarImage.size.height);
            avatar.transform = CGAffineTransformMakeScale(.28, .28);
        }
    }
    else {
        [avatar generateIdenticonWithShadow:false];
        avatar.frame = CGRectMake(-93, -99.5, avatar.userImage.size.width, avatar.userImage.size.height);
        avatar.transform = CGAffineTransformMakeScale(.16, .16);
    }
    avatar.userInteractionEnabled = false;
    avatar.tag = 402;
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
    
    if ([self.selectedUserID isEqualToString:self.availableUsersDict.allKeys[indexPath.row]]) self.selectedUserID = nil;
    else self.selectedUserID = self.availableUsersDict.allKeys[indexPath.row];
    [tableView reloadData];
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
