//
//  InviteToTeamViewController.m
//  quill
//
//  Created by Alex Costantini on 2/2/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "InviteToTeamViewController.h"
#import "FirebaseHelper.h"
#import <MailCore/mailcore.h>
#import "InviteEmail.h"
#import "Flurry.h"
#import "GeneralAlertViewController.h"
#import "TeamSizeAlertViewController.h"

@implementation InviteToTeamViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.cornerRadius = 10;
    self.inviteButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    if (self.creatingTeam) self.inviteEmails = [@[@""] mutableCopy];
    else self.inviteEmails = [NSMutableArray array];
    
    editedText = [NSMutableArray array];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    teamEmails = [NSMutableArray array];
    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSString *userEmail = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"email"];
        [teamEmails addObject:userEmail];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
        
    if (self.creatingTeam) {
        
        self.navigationItem.title = @"Step 3: Send Invites";
        
        self.inviteButton.frame = CGRectMake(115, 272, 310, 50);
        self.inviteTable.frame = CGRectMake(0, 0, 540, 212);
        self.inviteLabel.frame = CGRectMake(0, 219, 540, 48);
        self.inviteFade.frame = CGRectMake(0, 196, 540, 112);
        
        [self.inviteTable reloadData];
        
        UITableViewCell *cell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
        [textField becomeFirstResponder];
    }
    else {
        self.navigationItem.title = @"Send Invites";
        self.stepLabel.hidden = true;
        [self.inviteButton setTitle:@"Send" forState:UIControlStateNormal];
    }
}

-(void) viewDidAppear:(BOOL)animated {
    
    if (!self.creatingTeam) projectVC.handleOutsideTaps = true;
    
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        if (self.creatingTeam) {
            
            [Flurry logEvent:@"New_Owner-Sign_up-Step_3-Back_to_Team_Name" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
            logoImage.frame = CGRectMake(149, 8, 32, 32);
        }
        else if ([self.navigationController.viewControllers.lastObject isKindOfClass:[TeamSizeAlertViewController class]]) logoImage.frame = CGRectMake(95, 8, 32, 32);
        else logoImage.frame = CGRectMake(173, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    
    projectVC.handleOutsideTaps = false;
    
    [super viewWillDisappear:animated];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

- (NSString *) generateToken {
    
    NSString *alphanum = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    int length = 15;
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [alphanum characterAtIndex: arc4random_uniform([alphanum length]) % [alphanum length]]];
    }
    
    if ([FirebaseHelper sharedHelper].isDev) return @"tEsTtOkEn";
    else return randomString;
}

-(void) updateInviteEmails {

    NSInteger cellCount = self.inviteEmails.count;
    
    for (NSString *emailString in self.inviteEmails) {
        if (emailString.length == 0) [self.inviteEmails removeObject:emailString];
    }
    
    for (NSString *text in editedText) {
        [self.inviteEmails removeObject:text];
    }
    
    editedText = [NSMutableArray array];
    
    for (int i=0; i<cellCount; i++) {
        
        UITableViewCell *cell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
 
        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
        
        if (![self.inviteEmails containsObject:textField.text] && textField.text.length > 0) [self.inviteEmails addObject:textField.text];
    }
}

-(void) activateCells:(BOOL)activate {
    
    for (int i=0; i<self.inviteEmails.count; i++) {
        
        UITableViewCell *cell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
        if ([textField isFirstResponder]) [textField resignFirstResponder];
        
        if (activate) {
            
            cell.userInteractionEnabled = YES;
            cell.alpha = 1;
        }
        else {
            
            cell.userInteractionEnabled = NO;
            cell.alpha = 0.5;
        }
    }
}

-(void) deleteTapped:(id)sender {
    
    [self updateInviteEmails];
    
    UIButton *deleteButton = (UIButton *)sender;
    NSString *emailString = ((UITextField *)[deleteButton.superview viewWithTag:401]).text;
    
    [self.inviteEmails removeObject:emailString];
    [self.inviteTable reloadData];
}

- (IBAction)sendTapped:(id)sender {

    [self updateInviteEmails];
    
    if (self.inviteEmails.count == 0 && !self.creatingTeam) {
        
        self.inviteLabel.text = @"Please enter at least one email.";
        return;
    }
    
    [self activateCells:false];
    
    for (NSString *email in self.inviteEmails) {
        
        if ([teamEmails containsObject:email]) {
            self.inviteLabel.text = @"One or more of the emails entered is already in use by a teammate.\nPlease fix the emails in red.";
            [self activateCells:true];
            return;
        }
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    NSMutableArray *errorEmails = [NSMutableArray array];
    
    for (NSString *emailString in self.inviteEmails) {
        
        if (![emailTest evaluateWithObject:emailString]) [errorEmails addObject:emailString];
    }

    if (errorEmails.count == 0) {
        
        self.inviteButton.userInteractionEnabled = false;
        self.inviteButton.alpha = .5;
        
        __block BOOL emailsSent;
        __block BOOL nameCreated;
        __block BOOL teamCreated;
        __block BOOL teamSet;

        if (self.creatingTeam) {
            
            //////////Create Name
            NSString *nameString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/info/name", [FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
            Firebase *nameRef = [[Firebase alloc] initWithUrl:nameString];
            [nameRef setValue:[FirebaseHelper sharedHelper].userName withCompletionBlock:^(NSError *error, Firebase *ref) {
                nameCreated = true;
                if (teamCreated && teamSet && emailsSent && !invitesSent) [self invitesSent];
            }];
            
            
            //////////Create Team
            NSString *teamString = [NSString stringWithFormat:@"https://%@.firebaseio.com/teams", [FirebaseHelper sharedHelper].db];
            Firebase *teamRef = [[Firebase alloc] initWithUrl:teamString];
            
            if (![FirebaseHelper sharedHelper].teamID) [FirebaseHelper sharedHelper].teamID = [teamRef childByAutoId].key;
            
            NSDictionary *newTeamValues = @{ [FirebaseHelper sharedHelper].teamID :
                                                 @{ @"users" :
                                                        @{ [FirebaseHelper sharedHelper].uid : @1 },
                                                    @"name" : [FirebaseHelper sharedHelper].teamName
                                                    }
                                             };
            
            [teamRef updateChildValues:newTeamValues withCompletionBlock:^(NSError *error, Firebase *ref) {
                teamCreated = true;
                if (nameCreated && teamSet && emailsSent && !invitesSent) [self invitesSent];
            }];

            //////////Set Team
            NSString *userString = [NSString stringWithFormat:@"https://%@.firebaseio.com/users/%@/info/team",[FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].uid];
            Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
            [userRef setValue:[FirebaseHelper sharedHelper].teamID withCompletionBlock:^(NSError *error, Firebase *ref) {
                
                teamSet = true;

                if (nameCreated && teamCreated && emailsSent && !invitesSent) [self invitesSent];
            }];
        }
            
        //////////Send Emails
        if (self.inviteEmails.count == 0 && self.creatingTeam) {
            
            self.inviteLabel.text = @"Creating team...";
            emailsSent = true;
        }
        else {
            
            if (self.creatingTeam) self.inviteLabel.text = @"Creating team and sending invites...";
            else self.inviteLabel.text = @"Sending invites...";

            MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
            smtpSession.hostname = @"smtp.gmail.com";
            smtpSession.port = 465;
            smtpSession.username = @"hello@tigrillo.co";
            smtpSession.password = @"DRc4iK3NJZ;aKEodNoH/";
            smtpSession.authType = MCOAuthTypeSASLPlain;
            smtpSession.connectionType = MCOConnectionTypeTLS;
            
            __block int emailCount = 0;
            
            NSMutableDictionary *usersDict = [NSMutableDictionary dictionary];
            
            for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
                
                NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
                [usersDict setObject:userName forKey:userID];
            }
            
            for (NSString *userEmail in self.inviteEmails) {
                
                NSString *token = [self generateToken];
                NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
                
                NSString *tokenString = [NSString stringWithFormat:@"https://%@.firebaseio.com/tokens/%@",[FirebaseHelper sharedHelper].db, token];
                Firebase *tokenRef = [[Firebase alloc] initWithUrl:tokenString];
                
                NSDictionary *tokenDict = @{ @"teamID" : [FirebaseHelper sharedHelper].teamID,
                                             @"teamName" : [FirebaseHelper sharedHelper].teamName,
                                             @"email" : userEmail,
                                             @"invitedBy" : [FirebaseHelper sharedHelper].userName,
                                             @"users" : usersDict
                                             };
                
                [tokenRef setValue:tokenDict];
                
                MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
                MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"cos@tigrillo.co"];
                MCOAddress *to = [MCOAddress addressWithDisplayName:nil mailbox:userEmail];
                [[builder header] setFrom:from];
                [[builder header] setTo:@[to]];
                [[builder header] setSubject:@"Welcome to Quill!"];
                
                InviteEmail *inviteEmail = [[InviteEmail alloc] init];
                inviteEmail.inviteURL = tokenURL;
                [inviteEmail updateHTML];
                [builder setHTMLBody:inviteEmail.htmlBody];

                //[builder setTextBody:tokenURL];
                NSData * rfc822Data = [builder data];
                
                MCOSMTPSendOperation *sendOperation =
                [smtpSession sendOperationWithData:rfc822Data];
                [sendOperation start:^(NSError *error) {
                    if(error) NSLog(@"Error sending email: %@", error);
                    else {
                        emailCount++;
                        if (emailCount == self.inviteEmails.count) {
                            emailsSent = true;
                            if ((teamCreated && teamSet && nameCreated && !invitesSent) || (!self.creatingTeam && !invitesSent)) [self invitesSent];
                        }
                    }
                }];
            }
        }
    }
    else {
        
        self.inviteLabel.text = @"Please fix the emails in red.";
        [self activateCells:true];
    }
}

-(void) invitesSent {
    
    invitesSent = true;
    
    [Flurry logEvent:@"Invite_User-Invites_Sent" withParameters:
     @{ @"userID":[FirebaseHelper sharedHelper].uid,
        @"teamID":[FirebaseHelper sharedHelper].teamID,
        @"invites":@(self.inviteEmails.count),
        @"source": @"inviteToTeam"
        }];
    
    if (self.creatingTeam) {
        
        [Flurry logEvent:@"New_Owner-Sign_up-Step_3-Invitation_Complete" withParameters:@{@"teamID":[FirebaseHelper sharedHelper].teamID}];
        
        [[FirebaseHelper sharedHelper] observeLocalUser];
        
        if (self.inviteEmails.count == 0) self.inviteLabel.text = @"Team created!";
        else self.inviteLabel.text = @"Invites sent and team created!";
    }
    else {
        
        self.inviteLabel.text = @"Invites sent!";
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:.3];
    }
}

-(void) dismiss {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Text field handling

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.textColor = [UIColor blackColor];
    if (textField.text.length > 0) [editedText addObject:textField.text];
    
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.inviteTable indexPathForCell:cell];
    UIButton *deleteButton = (UIButton *)[cell.contentView viewWithTag:404];
    deleteButton.hidden = false;
    
    [self.inviteTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    UIButton *deleteButton = (UIButton *)[cell.contentView viewWithTag:404];
    

    if (textField.text.length > 0) {
        
        deleteButton.hidden = false;
        
        if (![emailTest evaluateWithObject:textField.text] || [teamEmails containsObject:textField.text]) textField.textColor = [UIColor redColor];
        else textField.textColor = [UIColor blackColor];
    }
    else deleteButton.hidden = true;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    
    if ([textField isFirstResponder]) [textField resignFirstResponder];
    
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.inviteEmails.count+1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == self.inviteEmails.count) return 65.0;
    else return 48.0;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (int i=1; i<7; i++) {
        
        if ([cell.contentView viewWithTag:400+i] != nil) [[cell.contentView viewWithTag:400+i] removeFromSuperview];
    }
        
    if (indexPath.row == self.inviteEmails.count) {
        
        UILabel *addUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 10, 0, 0)];
        addUserLabel.text = @"Add new teammate to invite by email";
        addUserLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
        addUserLabel.alpha = .5;
        [addUserLabel sizeToFit];
        addUserLabel.tag = 406;
        [cell.contentView addSubview:addUserLabel];
        
        UIImageView *plusImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus3.png"]];
        plusImage.frame = CGRectMake(14, 7, 35, 35);
        plusImage.alpha = .5;
        plusImage.tag = 405;
        [cell.contentView addSubview:plusImage];
    }
    else {
        
        cell.textLabel.hidden = true;
        
        NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
        
        UITextField *inviteTextField = [[UITextField alloc] initWithFrame:CGRectMake(64, 3, 240, 42)];
        inviteTextField.placeholder = @"Enter Email";
        inviteTextField.tag = 401;
        inviteTextField.delegate = self;
        inviteTextField.text = self.inviteEmails[indexPath.row];
        if (![emailTest evaluateWithObject:inviteTextField.text] || [teamEmails containsObject:inviteTextField.text]) inviteTextField.textColor = [UIColor redColor];
        inviteTextField.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
        [cell.contentView addSubview:inviteTextField];
        
        UIImageView *mailImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mail.png"]];
        mailImage.alpha = .3;
        mailImage.frame = CGRectMake(14, 7, 35, 35);
        mailImage.tag = 402;
        [cell.contentView addSubview:mailImage];
        
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setBackgroundImage:[UIImage imageNamed:@"minus2.png"] forState:UIControlStateNormal];
        deleteButton.frame = CGRectMake(485, 7, 35, 35);
        [deleteButton addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
        deleteButton.tag = 404;
        [cell.contentView addSubview:deleteButton];
        
        if (inviteTextField.text.length > 0) deleteButton.hidden = false;
        else deleteButton.hidden = true;

    }
 
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [UIView setAnimationsEnabled:NO];
    
    int cellCount = self.inviteEmails.count;
    [self updateInviteEmails];
    
    if (indexPath.row >= cellCount) {
        
        if ([[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys].count == 5) {
            
            [Flurry logEvent:@"Team_Size_Limit-Limit_Reached" withParameters: @{ @"teamID" : [FirebaseHelper sharedHelper].teamID }];
            
            TeamSizeAlertViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TeamSize"];
            
            logoImage.hidden = true;
            
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            
            [self.inviteEmails addObject:@""];
            [self.inviteTable reloadData];
            
            int newCellRow;
            
            if (indexPath.row == cellCount) newCellRow = cellCount;
            else newCellRow = cellCount-1;
            
            UITableViewCell *newCell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:newCellRow inSection:0]];
            [(UITextField *)[newCell.contentView viewWithTag:401] becomeFirstResponder];
        }
    }
    
    [UIView setAnimationsEnabled:YES];
}


@end
