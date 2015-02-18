//
//  InviteToTeamViewController.m
//  quill
//
//  Created by Alex Costantini on 2/2/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "InviteToTeamViewController.h"
#import "FirebaseHelper.h"
#import <MailCore/mailcore.h>
#import "InviteEmail.h"

@implementation InviteToTeamViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.cornerRadius = 10;
    self.inviteButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    self.inviteEmails = [NSMutableArray array];
    
    editedText = [NSMutableArray array];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
}

-(void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self.creatingTeam) self.navigationItem.title = @"Step 3: Send Invites";
    else {
        
        self.navigationItem.title = @"Send Invites";
        self.stepLabel.hidden = true;
        [self.inviteButton setTitle:@"Send" forState:UIControlStateNormal];
        
        outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
        
        [outsideTapRecognizer setDelegate:self];
        [outsideTapRecognizer setNumberOfTapsRequired:1];
        outsideTapRecognizer.cancelsTouchesInView = NO;
        [self.view.window addGestureRecognizer:outsideTapRecognizer];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        if (self.creatingTeam) logoImage.frame = CGRectMake(149, 8, 32, 32);
        else logoImage.frame = CGRectMake(173, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    
    if (!self.creatingTeam) {
        [outsideTapRecognizer setDelegate:nil];
        [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
    }
    
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
    
    return randomString;
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
            
            textField.userInteractionEnabled = true;
            textField.alpha = 1;
        }
        else {
            
            textField.userInteractionEnabled = false;
            textField.alpha = .5;
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
    
    [self activateCells:false];
    
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
            NSString *nameString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/name", [FirebaseHelper sharedHelper].uid];
            Firebase *nameRef = [[Firebase alloc] initWithUrl:nameString];
            [nameRef setValue:[FirebaseHelper sharedHelper].userName withCompletionBlock:^(NSError *error, Firebase *ref) {
                nameCreated = true;
                if (teamCreated && teamSet && emailsSent) [self invitesSent];
            }];
            
            NSLog(@"teamID is %@", [FirebaseHelper sharedHelper].userName);
            
            //////////Create Team
            Firebase *teamRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/teams"];
            
            [FirebaseHelper sharedHelper].teamID = [teamRef childByAutoId].key;
            
            NSLog(@"teamID is %@", [FirebaseHelper sharedHelper].teamID);
            
            NSDictionary *newTeamValues = @{ [FirebaseHelper sharedHelper].teamID :
                                                 @{ @"users" :
                                                        @{ [FirebaseHelper sharedHelper].uid : @1 },
                                                    @"name" : [FirebaseHelper sharedHelper].teamName
                                                    }
                                             };
            [teamRef updateChildValues:newTeamValues withCompletionBlock:^(NSError *error, Firebase *ref) {
                teamCreated = true;
                if (nameCreated && teamSet && emailsSent) [self invitesSent];
            }];

            //////////Set Team
            NSString *userString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/users/%@/team", [FirebaseHelper sharedHelper].uid];
            Firebase *userRef = [[Firebase alloc] initWithUrl:userString];
            [userRef setValue:[FirebaseHelper sharedHelper].teamID withCompletionBlock:^(NSError *error, Firebase *ref) {
                teamSet = true;
                
                NSLog(@"team set!");
                
                if (nameCreated && teamCreated && emailsSent) [self invitesSent];
            }];
        }
            
        //////////Send Emails
        if (self.inviteEmails.count == 0 && self.creatingTeam) {
            
            self.inviteLabel.text = @"Creating team...";
            emailsSent = true;
        }
        else {
            
            if (self.creatingTeam)
                self.inviteLabel.text = @"Creating team and sending invites...";
            else
                self.inviteLabel.text = @"Sending invites...";
            
            Firebase *tokenRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/tokens"];
            
            MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
            smtpSession.hostname = @"smtp.gmail.com";
            smtpSession.port = 465;
            smtpSession.username = @"cos@tigrillo.co";
            smtpSession.password = @"foothill94022";
            smtpSession.authType = MCOAuthTypeSASLPlain;
            smtpSession.connectionType = MCOConnectionTypeTLS;
            
            __block int emailCount = 0;
            
            for (NSString *userEmail in self.inviteEmails) {
                
                NSString *token = [self generateToken];
                NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
                NSString *teamIDString = [NSString stringWithFormat:@"%@/teamID", token];
                NSString *teamNameString = [NSString stringWithFormat:@"%@/teamName", token];
                NSString *emailString = [NSString stringWithFormat:@"%@/email", token];
                NSString *invitedByString = [NSString stringWithFormat:@"%@/invitedBy", token];
                
                [[tokenRef childByAppendingPath:teamIDString] setValue:[FirebaseHelper sharedHelper].teamID];
                [[tokenRef childByAppendingPath:teamNameString] setValue:[FirebaseHelper sharedHelper].teamName];
                [[tokenRef childByAppendingPath:emailString] setValue:userEmail];
                [[tokenRef childByAppendingPath:invitedByString] setValue:[FirebaseHelper sharedHelper].userName];
                
                MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
                MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"cos@tigrillo.co"];
                MCOAddress *to = [MCOAddress addressWithDisplayName:nil mailbox:userEmail];
                [[builder header] setFrom:from];
                [[builder header] setTo:@[to]];
                
                [[builder header] setSubject:@"Welcome to Quill!"];
                
//                InviteEmail *inviteEmail = [[InviteEmail alloc] init];
//                inviteEmail.inviteURL = tokenURL;
//                [inviteEmail updateHTML];
//                [builder setHTMLBody:inviteEmail.htmlBody];
                
                [builder setTextBody:tokenURL];
                NSData * rfc822Data = [builder data];
                
                MCOSMTPSendOperation *sendOperation =
                [smtpSession sendOperationWithData:rfc822Data];
                [sendOperation start:^(NSError *error) {
                    if(error) NSLog(@"Error sending email: %@", error);
                    else {
                        emailCount++;
                        if (emailCount == self.inviteEmails.count) {
                            emailsSent = true;
                            if ((teamCreated && teamSet && nameCreated) || !self.creatingTeam) [self invitesSent];
                        }
                    }
                }];
            }
        }
    }
    else {
        
        self.inviteLabel.text = @"Please fix the emails in red!";
        [self activateCells:true];
    }
}

-(void) invitesSent {
    
    if (self.creatingTeam) {
        
        [[FirebaseHelper sharedHelper] observeLocalUser];
        
        if (self.inviteEmails.count == 0) self.inviteLabel.text = @"Team created!";
        else self.inviteLabel.text = @"Invites sent and team created!";
    }
    else self.inviteLabel.text = @"Invites sent!";
    
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:.3];
}

-(void) dismiss {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
    }
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
        if (![emailTest evaluateWithObject:textField.text]) textField.textColor = [UIColor redColor];
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
        if (![emailTest evaluateWithObject:inviteTextField.text]) inviteTextField.textColor = [UIColor redColor];
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
        
        [self.inviteEmails addObject:@""];
        [self.inviteTable reloadData];
        
        int newCellRow;
        
        if (indexPath.row == cellCount) newCellRow = cellCount;
        else newCellRow = cellCount-1;
        
        UITableViewCell *newCell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:newCellRow inSection:0]];
        [(UITextField *)[newCell.contentView viewWithTag:401] becomeFirstResponder];
    }
    
    [UIView setAnimationsEnabled:YES];
}

@end
