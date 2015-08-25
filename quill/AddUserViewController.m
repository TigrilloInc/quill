//
//  AddUserViewController.m
//  Quill
//
//  Created by Alex Costantini on 10/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "AddUserViewController.h"
#import "FirebaseHelper.h"
#import "NSDate+ServerDate.h"
#import <MailCore/mailcore.h>
#import "InviteEmail.h"
#import "Flurry.h"
#import "GeneralAlertViewController.h"
#import "TeamSizeAlertViewController.h"

@implementation AddUserViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Invite Teammates to Project";
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle: @"Back"
                                   style: UIBarButtonItemStylePlain
                                   target:nil action:nil];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.selectedUsers = [NSMutableArray array];
    self.inviteEmails = [NSMutableArray array];
    self.roles = [NSMutableDictionary dictionary];
    editedText = [NSMutableArray array];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSMutableDictionary *usersDict = [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] mutableCopy];
    
    for (NSString *userID in usersDict.allKeys) {
        
        if ([projectVC.roles.allKeys containsObject:userID] && [[projectVC.roles objectForKey:userID] integerValue] != -1) [usersDict removeObjectForKey:userID];
    }
    self.availableUsersDict = usersDict;
    
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.cornerRadius = 10;
    self.inviteButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    teamEmails = [NSMutableArray array];
    
    for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
        
        NSString *userEmail = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"email"];
        [teamEmails addObject:userEmail];
    }
    
    //if (self.availableUsersDict.allKeys.count == 0) [self.inviteEmails addObject:@""];
}

- (void) viewDidAppear:(BOOL)animated {
    
    projectVC.handleOutsideTaps = true;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    projectVC.handleOutsideTaps = false;
}

- (NSString *) generateToken {
    
    NSString *alphanum = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    int length = 15;
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [alphanum characterAtIndex: arc4random_uniform([alphanum length]) % [alphanum length]]];
    }
    
    if ([FirebaseHelper sharedHelper].isDev) return @"tEsTtOkEn";
    else return randomString;
}

-(void) updateInviteEmails {
    
    NSInteger cellCount = self.availableUsersDict.allKeys.count+self.inviteEmails.count;
    
    for (NSString *emailString in self.inviteEmails) {
        if (emailString.length == 0) [self.inviteEmails removeObject:emailString];
    }
    
    for (NSString *text in editedText) {
        [self.inviteEmails removeObject:text];
        [self.roles removeObjectForKey:text];
    }
    editedText = [NSMutableArray array];
    
    for (int i=0; i<cellCount; i++) {
        
        UITableViewCell *cell = [self.usersTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        NSString *nameString;
        
        if (i<self.availableUsersDict.allKeys.count) {
            
            UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:408];
            nameString = nameLabel.text;
        }
        else {
            
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
            
            if (![self.inviteEmails containsObject:textField.text] && textField.text.length > 0) {
                [self.inviteEmails addObject:textField.text];
                nameString = textField.text;
            }
        }
        
        if (nameString.length > 0 && [cell.contentView viewWithTag:403] != nil) {

            UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
            [self.roles setObject:@(roleControl.selectedSegmentIndex) forKey:nameString];
        }
    }

    if (self.inviteEmails.count+self.selectedUsers.count > 1) [self.inviteButton setTitle:@"Send Invites" forState:UIControlStateNormal];
    else [self.inviteButton setTitle:@"Send Invite" forState:UIControlStateNormal];
}

-(void) invitesSent {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) activateCells:(BOOL)activate {

    for (int i=0; i<self.inviteEmails.count+self.availableUsersDict.allKeys.count; i++) {
        
        UITableViewCell *cell = [self.usersTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];

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

- (IBAction)addUserTapped:(id)sender {
    
    [self updateInviteEmails];
    
    if (self.inviteEmails.count+self.selectedUsers.count == 0) {
        
        self.inviteLabel.text = @"Please add at least one user.";
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
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSDictionary *newUndoDict = @{  @"currentIndex" : @0,
                                    @"currentIndexDate" : dateString,
                                    @"total" : @0
                                    };
    
    NSDictionary *newSubpathsDict = @{ dateString : @"penUp"};
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    NSMutableArray *errorEmails = [NSMutableArray array];
    
    for (NSString *emailString in self.inviteEmails) {
        
        if (![emailTest evaluateWithObject:emailString]) [errorEmails addObject:emailString];
    }
    
    if (errorEmails.count == 0) {
        
        self.inviteLabel.text = @"Sending invites...";
        self.inviteButton.alpha = .5;
        self.inviteButton.userInteractionEnabled = false;

        for (NSString *userID in self.selectedUsers) {
            
            NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
            
            [projectVC.roles setObject:[self.roles objectForKey:userName] forKey:userID];
            
            NSString *roleString;
            
            if ([[self.roles objectForKey:userName] integerValue] == 0) roleString = @"viewer";
            else roleString = @"collaborator";

            NSDictionary *flurryDict = @{ @"role" : roleString,
                                          @"projectID" : [FirebaseHelper sharedHelper].currentProjectID,
                                          @"teamID" : [FirebaseHelper sharedHelper].teamID
                                          };
            
            [Flurry logEvent:@"User_Added" withParameters:flurryDict];
            
            for (NSString *boardID in projectVC.boardIDs) {
                
                [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"undo"] setObject:[newUndoDict mutableCopy] forKey:userID];
                NSString *undoString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/undo/%@", [FirebaseHelper sharedHelper].db, boardID, userID];
                Firebase *undoRef = [[Firebase alloc] initWithUrl:undoString];
                [undoRef setValue:newUndoDict withCompletionBlock:^(NSError *error, Firebase *ref) {
                    [[FirebaseHelper sharedHelper] observeUndoForUser:userID onBoard:boardID];
                }];
                
                [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"subpaths"] setObject:[newSubpathsDict mutableCopy] forKey:userID];
                NSString *subpathsString = [NSString stringWithFormat:@"https://%@.firebaseio.com/boards/%@/subpaths/%@", [FirebaseHelper sharedHelper].db, boardID, userID];
                Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
                [subpathsRef setValue:newSubpathsDict withCompletionBlock:^(NSError *error, Firebase *ref) {
                    [[FirebaseHelper sharedHelper] observeSubpathsForUser:userID onBoard:boardID];
                }];
            }
        }
        
        NSString *projectString = [NSString stringWithFormat:@"https://%@.firebaseio.com/projects/%@/info/roles",[FirebaseHelper sharedHelper].db, [FirebaseHelper sharedHelper].currentProjectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [projectRef updateChildValues:projectVC.roles];
        
        if (self.inviteEmails.count > 0) {
            
            MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
            smtpSession.hostname = @"smtp.gmail.com";
            smtpSession.port = 465;
            smtpSession.username = @"hello@tigrillo.co";
            smtpSession.password = @"DRc4iK3NJZ;aKEodNoH/";
            smtpSession.authType = MCOAuthTypeSASLPlain;
            smtpSession.connectionType = MCOConnectionTypeTLS;
            
            NSMutableDictionary *usersDict = [NSMutableDictionary dictionary];
            
            for (NSString *userID in [[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys]) {
                
                NSString *userName = [[[[FirebaseHelper sharedHelper].team objectForKey:@"users"] objectForKey:userID] objectForKey:@"name"];
                [usersDict setObject:userName forKey:userID];
            }
            
            for (NSString *userEmail in self.inviteEmails) {
                
                NSString *token = [self generateToken];
                NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
                
                NSString *tokenString = [NSString stringWithFormat:@"https://%@.firebaseio.com/tokens/%@", [FirebaseHelper sharedHelper].db,token];
                Firebase *tokenRef = [[Firebase alloc] initWithUrl:tokenString];
 
                NSDictionary *tokenDict = @{ @"teamID" : [FirebaseHelper sharedHelper].teamID,
                                             @"teamName" : [FirebaseHelper sharedHelper].teamName,
                                             @"project" : @{[FirebaseHelper sharedHelper].currentProjectID :
                                                                [self.roles objectForKey:userEmail]},
                                             @"email" : userEmail,
                                             @"invitedBy" : [FirebaseHelper sharedHelper].userName,
                                             @"users" : usersDict
                                                 };
                [tokenRef setValue:tokenDict];
                
                MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
                MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"hello@tigrillo.co"];
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
                        
                        [Flurry logEvent:@"Invite_User-Invites_Sent" withParameters:
                         @{ @"userID":[FirebaseHelper sharedHelper].uid,
                            @"teamID":[FirebaseHelper sharedHelper].teamID,
                            @"invites":@(self.inviteEmails.count),
                            @"source": @"addUser"
                            }];
                        
                        self.inviteLabel.text = @"Invites Sent!";
                        [projectVC updateDetails:NO];
                        [self performSelector:@selector(invitesSent) withObject:nil afterDelay:0.5];
                    }
                }];
            }
        }
        else {
            
            self.inviteLabel.text = @"Invites Sent!";
            [projectVC updateDetails:NO];
            [self invitesSent];
        }
    }
    else {

        [self activateCells:true];
        self.inviteLabel.text = @"Please fix the emails in red.";
    }

}

-(void) roleTapped:(id)sender {
    
    UISegmentedControl *roleControl = (UISegmentedControl *)sender;
    UITableViewCell *cell = (UITableViewCell *)roleControl.superview.superview;
    
    NSString *userString;
    
    if ([cell.contentView viewWithTag:401]) userString = ((UITextField *)[cell.contentView viewWithTag:401]).text;
    else userString = ((UILabel *)[cell.contentView viewWithTag:408]).text;
    
    [self.roles setObject:@(roleControl.selectedSegmentIndex) forKey:userString];
    
}

-(void) deleteTapped:(id)sender {

    [self updateInviteEmails];
    
    UIButton *deleteButton = (UIButton *)sender;
    NSString *emailString = ((UITextField *)[deleteButton.superview viewWithTag:401]).text;
    
    [self.inviteEmails removeObject:emailString];
    [self.roles removeObjectForKey:emailString];
    [self.usersTable reloadData];
    
    if (self.inviteEmails.count+self.selectedUsers.count > 1) [self.inviteButton setTitle:@"Send Invites" forState:UIControlStateNormal];
    else [self.inviteButton setTitle:@"Send Invite" forState:UIControlStateNormal];
}

#pragma mark - Text field handling

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.textColor = [UIColor blackColor];
    if (textField.text.length > 0) [editedText addObject:textField.text];
    
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.usersTable indexPathForCell:cell];
    UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
    UIButton *deleteButton = (UIButton *)[cell.contentView viewWithTag:404];
    roleControl.hidden = false;
    deleteButton.hidden = false;
    
    [self.usersTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
    UIButton *deleteButton = (UIButton *)[cell.contentView viewWithTag:404];
    
    if (textField.text.length > 0) {
        
        roleControl.hidden = false;
        deleteButton.hidden = false;

        if (![emailTest evaluateWithObject:textField.text] || [teamEmails containsObject:textField.text]) textField.textColor = [UIColor redColor];
        else textField.textColor = [UIColor blackColor];
    }
    else {
        roleControl.hidden = true;
        deleteButton.hidden = true;
    }
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
    
    return self.availableUsersDict.allKeys.count+self.inviteEmails.count+1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == self.availableUsersDict.allKeys.count+self.inviteEmails.count) return 65.0;
    else return 48.0;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (int i=1; i<10; i++) {
        
        if ([cell.contentView viewWithTag:400+i] != nil) [[cell.contentView viewWithTag:400+i] removeFromSuperview];
    }

    if (indexPath.row < self.availableUsersDict.allKeys.count) {
        
        NSString *userID = self.availableUsersDict.allKeys[indexPath.row];
        
        UILabel *userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 11, 0, 0)];
        userNameLabel.text = [[self.availableUsersDict objectForKey:userID] objectForKey:@"name"];
        userNameLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
        [userNameLabel sizeToFit];
        userNameLabel.tag = 408;
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
        avatar.tag = 406;
        [cell.contentView addSubview:avatar];
        
        UIImageView *checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(485, 6, 35, 35)];
        checkImageView.tag = 407;
        [cell.contentView addSubview:checkImageView];
        
        if ([self.selectedUsers containsObject:userID]) {
            
            checkImageView.image = [UIImage imageNamed:@"checked.png"];
            checkImageView.alpha = 1;
            avatar.alpha = 1;
            userNameLabel.alpha = 1;
            
            UISegmentedControl *roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Viewer", @"Collaborator"]];
            roleControl.frame = CGRectMake(288, 5, 180, 38);
            roleControl.tintColor = [UIColor lightGrayColor];
            NSInteger roleInt;
            if (projectVC.userRole == 0) {
                roleControl.userInteractionEnabled = false;
                roleControl.alpha = .5;
                roleInt = 0;
            }
            else if ([self.roles objectForKey:userNameLabel.text] == nil) roleInt = 1;
            else roleInt = [[self.roles objectForKey:userNameLabel.text] integerValue];
            roleControl.selectedSegmentIndex = roleInt;
            [roleControl addTarget:self action:@selector(roleTapped:) forControlEvents:UIControlEventValueChanged];
            [roleControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"SourceSansPro-Light" size:13]} forState:UIControlStateNormal];
            roleControl.tag = 403;
            [cell.contentView addSubview:roleControl];
            
        }
        else {
            
            checkImageView.image = [UIImage imageNamed:@"unchecked.png"];
            checkImageView.alpha = .3;
            avatar.alpha = .3;
            userNameLabel.alpha = .3;
        }
    }
    else {
        
        if (indexPath.row == self.inviteEmails.count+self.availableUsersDict.allKeys.count) {

            UILabel *addUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 10, 0, 0)];
            addUserLabel.text = @"Add new user to invite by email";
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
        else {
            
            cell.textLabel.hidden = true;

            NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
            NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];

            UITextField *inviteTextField = [[UITextField alloc] initWithFrame:CGRectMake(64, 3, 240, 42)];
            inviteTextField.placeholder = @"Enter Email";
            inviteTextField.tag = 401;
            inviteTextField.delegate = self;
            inviteTextField.text = self.inviteEmails[indexPath.row-self.availableUsersDict.allKeys.count];
            if (![emailTest evaluateWithObject:inviteTextField.text] || [teamEmails containsObject:inviteTextField.text]) inviteTextField.textColor = [UIColor redColor];
            inviteTextField.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
            [cell.contentView addSubview:inviteTextField];
            
            UIImageView *mailImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mail.png"]];
            mailImage.alpha = .3;
            mailImage.frame = CGRectMake(14, 6, 35, 35);
            mailImage.tag = 402;
            [cell.contentView addSubview:mailImage];
            
            UISegmentedControl *roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Viewer", @"Collaborator"]];
            roleControl.frame = CGRectMake(288, 5, 180, 38);
            roleControl.tintColor = [UIColor lightGrayColor];
            int roleInt;
            if (projectVC.userRole == 0) {
                roleControl.userInteractionEnabled = false;
                roleControl.alpha = .5;
                roleInt = 0;
            }
            else if ([self.roles objectForKey:inviteTextField.text] == nil) roleInt = 1;
            else roleInt = [[self.roles objectForKey:inviteTextField.text] integerValue];
            roleControl.selectedSegmentIndex = roleInt;
            [roleControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"SourceSansPro-Light" size:13]} forState:UIControlStateNormal];
            [roleControl addTarget:self action:@selector(roleTapped:) forControlEvents:UIControlEventValueChanged];
            roleControl.tag = 403;
            [cell.contentView addSubview:roleControl];
            
            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setBackgroundImage:[UIImage imageNamed:@"minus2.png"] forState:UIControlStateNormal];
            deleteButton.frame = CGRectMake(485, 6, 35, 35);
            [deleteButton addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
            deleteButton.tag = 404;
            [cell.contentView addSubview:deleteButton];
            
            if (inviteTextField.text.length > 0) {
                deleteButton.hidden = false;
                roleControl.hidden = false;
            }
            else {
                deleteButton.hidden = true;
                roleControl.hidden = true;
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [UIView setAnimationsEnabled:NO];
    
    NSInteger cellCount = self.availableUsersDict.allKeys.count+self.inviteEmails.count;
    [self updateInviteEmails];
    
    if (indexPath.row < self.availableUsersDict.allKeys.count) {
        
        [UIView setAnimationsEnabled:YES];
        
        NSString *userID = self.availableUsersDict.allKeys[indexPath.row];
        
        if ([self.selectedUsers containsObject:userID]) [self.selectedUsers removeObject:userID];
        else [self.selectedUsers addObject:userID];
        
        [self.usersTable reloadData];
    }
    else if (indexPath.row >= cellCount) {
        
        if ([[[FirebaseHelper sharedHelper].team objectForKey:@"users"] allKeys].count == 1) {
            
            [Flurry logEvent:@"Team_Size_Limit-Limit_Reached" withParameters: @{ @"teamID" : [FirebaseHelper sharedHelper].teamID }];
            
            TeamSizeAlertViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"TeamSize"];
            
            logoImage.hidden = true;
            logoImage.frame = CGRectMake(95, 8, 32, 32);
            
            [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            
            [self.inviteEmails addObject:@""];
            [self.usersTable reloadData];

            int newCellRow;
            
            if (indexPath.row == cellCount) newCellRow = cellCount;
            else newCellRow = cellCount-1;
            
            UITableViewCell *newCell = [self.usersTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:newCellRow inSection:0]];
            [(UITextField *)[newCell.contentView viewWithTag:401] becomeFirstResponder];
        }
    }
    
    [UIView setAnimationsEnabled:YES];
}

-(void)showLogo {
    
    logoImage.alpha = 0;
    logoImage.hidden = false;
    
    [UIView animateWithDuration:.3 animations:^{
        logoImage.alpha = 1;
    }];
}

@end
