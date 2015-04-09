//
//  TeamSettingsViewController.m
//  quill
//
//  Created by Alex Costantini on 1/25/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "TeamSettingsViewController.h"
#import "FirebaseHelper.h"
#import "InviteToTeamViewController.h"
#import "RemoveUserAlertViewController.h"
#import "ProjectDetailViewController.h"
#import "InviteNewOwnerViewController.h"

@implementation TeamSettingsViewController

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    isOwner = [[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:[FirebaseHelper sharedHelper].uid] objectForKey:@"teamOwner"] integerValue];
    
    self.usersDict = [NSMutableDictionary dictionary];
    
    self.navigationItem.title = @"Team Settings";
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.doneButton.layer.borderWidth = 1;
    self.doneButton.layer.cornerRadius = 10;
    self.doneButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Settings"
                                   style: UIBarButtonItemStyleBordered
                                   target:self action:nil];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    if ([FirebaseHelper sharedHelper].isAdmin || [FirebaseHelper sharedHelper].isDev) {
        
        UIBarButtonItem *signOutButton = [[UIBarButtonItem alloc]
                                          initWithTitle: @"Invite Owner"
                                          style: UIBarButtonItemStyleBordered
                                          target: self action: @selector(inviteOwnerTapped)];
        [self.navigationItem setRightBarButtonItems:@[signOutButton] animated:NO];
    }
    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        if ([[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"deleted"] integerValue] == 1) continue;
        
        NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
        NSString *userName = (NSString *)[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
        NSString *userEmail = (NSString *)[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"email"];
        
        [userDict setObject:userName forKey:@"name"];
        [userDict setObject:userEmail forKey:@"email"];
        
        [self.usersDict setObject:userDict forKey:userID];
    }

    self.teamNameTextField.text = [FirebaseHelper sharedHelper].teamName;
    
    CGRect nameRect = [self.teamNameTextField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:28]} context:nil];
    
    self.editNameButton.center = CGPointMake(nameRect.size.width+50, self.editNameButton.center.y);
    if (!isOwner) self.editNameButton.hidden = true;
}

- (void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(IBAction)editNameTapped:(id)sender {
    
    self.teamNameTextField.userInteractionEnabled = YES;
    [self.teamNameTextField becomeFirstResponder];
}

-(void)deleteTapped:(id)sender {
    
    UIButton *deleteButton = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)deleteButton.superview.superview;
    NSIndexPath *indexPath = [self.usersTable indexPathForCell:cell];
    
    NSString *userID = self.usersDict.allKeys[indexPath.row];
    
    RemoveUserAlertViewController *removeUserVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RemoveUser"];
    removeUserVC.userID = userID;

    [self.navigationController pushViewController:removeUserVC animated:YES];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

- (IBAction)doneTapped:(id)sender {

    if (![self.teamNameTextField.text isEqualToString:[FirebaseHelper sharedHelper].teamName]) {
        
        if (self.teamNameTextField.text.length < 2) {
            
            self.teamLabel.text = @"Team names must be at least 2 characters long.";
        }
        else {
            NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams/%@/name", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].teamID];
            Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
            
            [FirebaseHelper sharedHelper].teamName = self.teamNameTextField.text;
            [teamRef setValue:[FirebaseHelper sharedHelper].teamName];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)inviteOwnerTapped {
    
    logoImage.hidden = true;
    logoImage.frame = CGRectMake(129, 8, 32, 32);
    
    [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    
    InviteNewOwnerViewController *inviteVC = [self.storyboard instantiateViewControllerWithIdentifier:@"InviteNewOwner"];
    [self.navigationController pushViewController:inviteVC animated:YES];
}

-(void)tappedOutside {
    
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
    
    return self.usersDict.allKeys.count+1;
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
    
    for (int i=1; i<5; i++) {
        
        if ([cell.contentView viewWithTag:500+i] != nil) [[cell.contentView viewWithTag:400+i] removeFromSuperview];
    }
    
    if (indexPath.row < self.usersDict.allKeys.count) {
        
        NSString *userID = self.usersDict.allKeys[indexPath.row];
        
        UILabel *userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 11, 0, 0)];
        userNameLabel.text = [[self.usersDict objectForKey:userID] objectForKey:@"name"];
        userNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
        [userNameLabel sizeToFit];
        userNameLabel.tag = 501;
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
        avatar.tag = 502;
        [cell.contentView addSubview:avatar];
        
        UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(190, 11, 0, 0)];
        emailLabel.text = [[self.usersDict objectForKey:userID] objectForKey:@"email"];
        emailLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:15];
        [emailLabel sizeToFit];
        emailLabel.tag = 503;
        [cell.contentView addSubview:emailLabel];
        
        if (isOwner && ![userID isEqualToString:[FirebaseHelper sharedHelper].uid]) {
            
            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setBackgroundImage:[UIImage imageNamed:@"minus2.png"] forState:UIControlStateNormal];
            deleteButton.frame = CGRectMake(480, 6, 35, 35);
            [deleteButton addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
            deleteButton.tag = 504;
            [cell.contentView addSubview:deleteButton];
        }
    }
    else {
        
        UILabel *addUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 10, 0, 0)];
        addUserLabel.text = @"Invite new teammates...";
        addUserLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
        addUserLabel.alpha = .3;
        [addUserLabel sizeToFit];
        addUserLabel.tag = 409;
        [cell.contentView addSubview:addUserLabel];
        
        UIImageView *plusImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus3.png"]];
        plusImage.frame = CGRectMake(14, 6, 35, 35);
        plusImage.alpha = .3;
        plusImage.tag = 405;
        [cell.contentView addSubview:plusImage];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == self.usersDict.allKeys.count) {
        
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(182, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
        
        InviteToTeamViewController *inviteVC = [self.storyboard instantiateViewControllerWithIdentifier:@"InviteToTeam"];
        [self.navigationController pushViewController:inviteVC animated:YES];
    }
}

#pragma mark - Text field handling

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    
    if ([self.teamNameTextField isFirstResponder]) [self.teamNameTextField resignFirstResponder];
    
    return NO;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    self.editNameButton.hidden = true;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    
    textField.userInteractionEnabled = NO;
    
    if (textField.text.length == 0) textField.text = [FirebaseHelper sharedHelper].teamName;
    
    if (textField.text.length == 1) textField.textColor = [UIColor redColor];
    else textField.textColor = [UIColor blackColor];
    
    CGRect nameRect = [textField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:28]} context:nil];
    
    self.editNameButton.center = CGPointMake(nameRect.size.width+50, self.editNameButton.center.y);
    self.editNameButton.hidden = false;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if(range.length + range.location > textField.text.length) return NO;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    
    if (newLength > 16) return NO;
    else return YES;

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
