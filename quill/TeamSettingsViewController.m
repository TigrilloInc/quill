//
//  TeamSettingsViewController.m
//  quill
//
//  Created by Alex Costantini on 1/25/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "TeamSettingsViewController.h"
#import "FirebaseHelper.h"
#import "InviteToTeamViewController.h"

@implementation TeamSettingsViewController

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.usersDict = [NSMutableDictionary dictionary];
    
    self.navigationItem.title = @"Team Settings";
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Settings"
                                   style: UIBarButtonItemStyleBordered
                                   target:self action:nil];
    [backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont fontWithName:@"SourceSansPro-Semibold" size:16],NSFontAttributeName,
                                        nil] forState:UIControlStateNormal];
    [self.navigationItem setBackBarButtonItem: backButton];

    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
        NSString *userName = (NSString *)[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
        NSString *userEmail = (NSString *)[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"email"];
        
        [userDict setObject:userName forKey:@"name"];
        [userDict setObject:userEmail forKey:@"email"];
        
        [self.usersDict setObject:userDict forKey:userID];
    }

    self.teamNameTextField.text = [FirebaseHelper sharedHelper].teamName;

    CGRect nameRect = [self.teamNameTextField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:28]} context:nil];
    
    self.editNameButton.center = CGPointMake(nameRect.size.width+75, self.editNameButton.center.y);
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
    
    if (![self.teamNameTextField.text isEqualToString:[FirebaseHelper sharedHelper].teamName]) {
     
        NSString *teamString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/teams/%@/name", [FirebaseHelper sharedHelper].teamID];
        Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
        
        [FirebaseHelper sharedHelper].teamName = self.teamNameTextField.text;
        
        [teamRef setValue:[FirebaseHelper sharedHelper].teamName];
    }
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
}

-(IBAction)editNameTapped:(id)sender {
    
    self.teamNameTextField.userInteractionEnabled = YES;
    [self.teamNameTextField becomeFirstResponder];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
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
    
    for (int i=1; i<4; i++) {
        
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
        [avatar generateIdenticonWithShadow:false];
        avatar.frame = CGRectMake(-93, -99.5, avatar.userImage.size.width, avatar.userImage.size.height);
        avatar.transform = CGAffineTransformMakeScale(.16, .16);
        avatar.tag = 502;
        avatar.userInteractionEnabled = false;
        [cell.contentView addSubview:avatar];
        
        UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(185, 11, 0, 0)];
        emailLabel.text = [[self.usersDict objectForKey:userID] objectForKey:@"email"];
        emailLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:18];
        [emailLabel sizeToFit];
        emailLabel.tag = 503;
        [cell.contentView addSubview:emailLabel];
        
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
    
    if (textField.text == 0) textField.text = [FirebaseHelper sharedHelper].teamName;
    
    CGRect nameRect = [textField.text boundingRectWithSize:CGSizeMake(1000,NSUIntegerMax) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{ NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Regular" size:28]} context:nil];
    
    self.editNameButton.center = CGPointMake(nameRect.size.width+75, self.editNameButton.center.y);
    self.editNameButton.hidden = false;
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
