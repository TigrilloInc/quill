//
//  TeamSettingsViewController.m
//  quill
//
//  Created by Alex Costantini on 1/25/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "TeamSettingsViewController.h"
#import "FirebaseHelper.h"

@implementation TeamSettingsViewController

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.usersDict = [NSMutableDictionary dictionary];
    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
        NSString *userName = (NSString *)[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
        NSString *userEmail = (NSString *)[[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"email"];
        
        [userDict setObject:userName forKey:@"name"];
        [userDict setObject:userEmail forKey:@"email"];
        
        [self.usersDict setObject:userDict forKey:userID];
    }

    NSLog(@"userDict is %@", self.usersDict);
    
    self.teamNameTextField.text = [FirebaseHelper sharedHelper].teamName;
    [self.teamNameTextField sizeToFit];
    self.teamNameTextField.center = CGPointMake(270, self.teamNameTextField.center.y);
    self.teamNameTextField.userInteractionEnabled = NO;
    
    self.iconImageView.center = CGPointMake(self.teamNameTextField.frame.origin.x-20, self.iconImageView.center.y);
    self.editNameButton.center = CGPointMake(self.teamNameTextField.frame.origin.x+self.teamNameTextField.frame.size.width+10, self.editNameButton.center.y);
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

-(IBAction)editNameTapped:(id)sender {
    
    self.teamNameTextField.userInteractionEnabled = YES;
    
    self.teamNameTextField.hidden = true;
    self.editNameButton.hidden = true;
    self.teamNameTextField.hidden = false;
    
    [self.teamNameTextField becomeFirstResponder];
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
