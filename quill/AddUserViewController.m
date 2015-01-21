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

@implementation AddUserViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.selectedUsers = [NSMutableArray array];
    self.inviteEmails = [NSMutableArray array];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    NSMutableDictionary *usersDict = (NSMutableDictionary *)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFDictionaryRef)[[FirebaseHelper sharedHelper].team objectForKey:@"users"], kCFPropertyListMutableContainers));
    for (NSString *userID in usersDict.allKeys) {
        
        if ([projectVC.roles.allKeys containsObject:userID]) [usersDict removeObjectForKey:userID];
    }
    self.availableUsersDict = usersDict;
    
    [self.inviteEmails addObject:@""];
}

- (void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [outsideTapRecognizer setDelegate:nil];
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)keyboardWillShow:(NSNotification *)notification {

    
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
//    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
//    [UIView setAnimationBeginsFromCurrentState:YES];

//    [self.usersTable setFrame:CGRectMake(0, 44, 540, 200)];
    
//    UIEdgeInsets insets = self.usersTable.contentInset;
//    insets.bottom += 200;
//    self.usersTable.contentInset = insets;
//
//    self.inviteButton.center = CGPointMake(self.inviteButton.center.x, 310);
//    
//    [UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification *)notification {

//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
//    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
//    [UIView setAnimationBeginsFromCurrentState:YES];
    
    
    //[self.usersTable setFrame:CGRectMake(0, 44, 540, 400)];

    
//    UIEdgeInsets insets = self.usersTable.contentInset;
//    insets.bottom -= 200;
//    self.usersTable.contentInset = insets;

    
//    self.inviteButton.center = CGPointMake(self.inviteButton.center.x, 540);
    
//    [UIView commitAnimations];
}

- (NSString *) generateToken {
    
    NSString *alphanum = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    int length = 15;
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [alphanum characterAtIndex: arc4random_uniform([alphanum length]) % [alphanum length]]];
    }
    
    return randomString;
}

-(void) updateInviteEmails {
    
    self.inviteEmails = [NSMutableArray array];
    
    for (int i=self.availableUsersDict.allKeys.count; i<self.usersTable.visibleCells.count-1; i++) {
        
        UITableViewCell *cell = self.usersTable.visibleCells[i];
        
        if ([cell.contentView viewWithTag:401]) {
            
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
            
            if (textField.text.length == 0) [self.inviteEmails addObject:@""];
            else [self.inviteEmails addObject:textField.text];
        }
    }
}

-(void) updateErrorEmails {
    
//    self.errorEmails = [NSMutableArray array];
//    
//    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
//    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
//    
//    for (int i=self.availableUsersDict.allKeys.count; i<self.usersTable.visibleCells.count-1; i++) {
//        
//        UITableViewCell *cell = self.usersTable.visibleCells[i];
//        
//        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
//        NSString *emailString = textField.text;
//        
//        if (![emailTest evaluateWithObject:emailString]) {
//            
//            [self.errorEmails addObject:emailString];
//            textField.textColor = [UIColor redColor];
//        }
//    }
}

-(void) invitesSent {
    
    [outsideTapRecognizer setDelegate:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addUserTapped:(id)sender {
    
    NSString *dateString = [NSString stringWithFormat:@"%.f", [[NSDate serverDate] timeIntervalSince1970]*100000000];
    
    NSDictionary *newUndoDict = @{  @"currentIndex" : @0,
                                    @"currentIndexDate" : dateString,
                                    @"total" : @0
                                    };    
    
    NSDictionary *newSubpathsDict = @{ dateString : @"penUp"};
    
    NSMutableArray *userIDs = [NSMutableArray array];
    NSMutableDictionary *userEmails = [NSMutableDictionary dictionary];
    NSMutableArray *errorEmails = [NSMutableArray array];
    
    for (int i=0; i<self.usersTable.visibleCells.count-1; i++) {
        
        UITableViewCell *cell = self.usersTable.visibleCells[i];
        
        if (i<self.availableUsersDict.allKeys.count) {
            
            NSString *userID = self.availableUsersDict.allKeys[i];
            
            NSLog(@"userID is %@", userID);
            
            if ([self.selectedUsers containsObject:userID]) {
                    
                UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
                [projectVC.roles setObject:@(roleControl.selectedSegmentIndex) forKey:userID];
                [userIDs addObject:userID];
            }
        }
        else {
         
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
            
            if (textField.text.length > 0) {
                
                UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
                [userEmails setObject:@(roleControl.selectedSegmentIndex) forKey:textField.text];
            }
        }
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];

    for (int i=self.availableUsersDict.allKeys.count; i<self.usersTable.visibleCells.count-1; i++) {

        UITableViewCell *cell = self.usersTable.visibleCells[i];

        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
        NSString *emailString = textField.text;

        if (![emailTest evaluateWithObject:emailString] && textField.text.length > 0) [errorEmails addObject:emailString];
    }
    
    if (errorEmails.count == 0) {
        
        [self.inviteButton setTitle:@"Sending invites..." forState:UIControlStateNormal];
        self.inviteButton.userInteractionEnabled = false;
        
        NSString *projectString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/projects/%@/info/roles", [FirebaseHelper sharedHelper].currentProjectID];
        Firebase *projectRef = [[Firebase alloc] initWithUrl:projectString];
        [projectRef updateChildValues:projectVC.roles];

        for (NSString *userID in userIDs) {
            
            for (NSString *boardID in projectVC.boardIDs) {
                
                [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"undo"] setObject:[newUndoDict mutableCopy] forKey:userID];
                NSString *undoString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/undo/%@", boardID, userID];
                Firebase *undoRef = [[Firebase alloc] initWithUrl:undoString];
                [undoRef setValue:newUndoDict withCompletionBlock:^(NSError *error, Firebase *ref) {
                    [[FirebaseHelper sharedHelper] observeUndoForUser:userID onBoard:boardID];
                }];
                
                [[[[FirebaseHelper sharedHelper].boards objectForKey:boardID] objectForKey:@"subpaths"] setObject:[newSubpathsDict mutableCopy] forKey:userID];
                NSString *subpathsString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/boards/%@/subpaths/%@", boardID, userID];
                Firebase *subpathsRef = [[Firebase alloc] initWithUrl:subpathsString];
                [subpathsRef setValue:newSubpathsDict withCompletionBlock:^(NSError *error, Firebase *ref) {
                    [[FirebaseHelper sharedHelper] observeSubpathsForUser:userID onBoard:boardID];
                }];
            }
        }
        
        if (userEmails.allKeys.count > 0) {
            
            Firebase *tokenRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/tokens"];

            MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
            smtpSession.hostname = @"smtp.gmail.com";
            smtpSession.port = 465;
            smtpSession.username = @"cos@tigrillo.co";
            smtpSession.password = @"foothill94022";
            smtpSession.authType = MCOAuthTypeSASLPlain;
            smtpSession.connectionType = MCOConnectionTypeTLS;
            
            for (NSString *userEmail in userEmails.allKeys) {
                    
                NSString *token = [self generateToken];
                NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
                NSString *teamString = [NSString stringWithFormat:@"%@/team", token];
                NSString *projectString = [NSString stringWithFormat:@"%@/project/%@", token, [FirebaseHelper sharedHelper].currentProjectID];
                NSString *emailString = [NSString stringWithFormat:@"%@/email", token];
                
                [[tokenRef childByAppendingPath:teamString] setValue:[FirebaseHelper sharedHelper].teamName];
                [[tokenRef childByAppendingPath:projectString] setValue:[userEmails objectForKey:userEmail]];
                [[tokenRef childByAppendingPath:emailString] setValue:userEmail];
                
                MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
                MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"cos@tigrillo.co"];
                MCOAddress *to = [MCOAddress addressWithDisplayName:nil mailbox:userEmail];
                [[builder header] setFrom:from];
                [[builder header] setTo:@[to]];
                
                [[builder header] setSubject:@"Welcome to Quill!"];
                //[builder setHTMLBody:@""];
                [builder setTextBody:tokenURL];
                NSData * rfc822Data = [builder data];
                
                MCOSMTPSendOperation *sendOperation =
                [smtpSession sendOperationWithData:rfc822Data];
                [sendOperation start:^(NSError *error) {
                    if(error) NSLog(@"Error sending email: %@", error);
                    else {
                        
                        [self.inviteButton setTitle:@"Invites Sent!" forState:UIControlStateNormal];
                        [projectVC updateDetails];
                        [self performSelector:@selector(invitesSent) withObject:nil afterDelay:0.5];
                    }
                }];
            }
        }
        else {
            
            [self.inviteButton setTitle:@"Invites Sent!" forState:UIControlStateNormal];
            [projectVC updateDetails];
            [self invitesSent];
        }
    }
    else {

        [projectVC updateDetails];
        [self invitesSent];
    }

}

-(void) deleteTapped:(id)sender {

    [self updateInviteEmails];
    
    UIButton *deleteButton = (UIButton *)sender;
    NSString *emailString = ((UITextField *)[deleteButton.superview viewWithTag:401]).text;
    
    [self.inviteEmails removeObject:emailString];
    if (self.usersTable.visibleCells.count == 2) [self.inviteEmails addObject:@""];
    [self.usersTable reloadData];
    
}

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)) [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Text field handling

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    if (![emailTest evaluateWithObject:textField.text] && textField.text.length > 0) textField.textColor = [UIColor redColor];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.textColor = [UIColor blackColor];
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

    return 48.0;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    cell.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
    
    for (int i=1; i<8; i++) {
        
        if ([cell.contentView viewWithTag:400+i]) [[cell.contentView viewWithTag:400+i] removeFromSuperview];
    }
    
    if (indexPath.row < self.availableUsersDict.allKeys.count) {
        
        NSString *userID = self.availableUsersDict.allKeys[indexPath.row];
        cell.textLabel.text = [[self.availableUsersDict objectForKey:userID] objectForKey:@"name"];
        
        AvatarButton *avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
        avatar.userID = userID;
        [avatar generateIdenticonWithShadow:false];
        avatar.frame = CGRectMake(-93, -100, avatar.userImage.size.width, avatar.userImage.size.height);
        avatar.transform = CGAffineTransformMakeScale(.16, .16);
        avatar.tag = 406;
        avatar.userInteractionEnabled = false;
        [cell.contentView addSubview:avatar];
        
        UIImageView *checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(485, 6, 35, 35)];
        checkImageView.tag = 407;
        [cell.contentView addSubview:checkImageView];
        
        if ([self.selectedUsers containsObject:userID]) {
            
            checkImageView.image = [UIImage imageNamed:@"checked.png"];
            checkImageView.alpha = 1;
            avatar.alpha = 1;
            cell.textLabel.alpha = 1;
            
            UISegmentedControl *roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Viewer", @"Collaborator"]];
            roleControl.center = CGPointMake(400, cell.frame.size.height/2);
            roleControl.tintColor = [UIColor lightGrayColor];
            roleControl.selectedSegmentIndex = 1;
            [roleControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"SourceSansPro-Light" size:13]} forState:UIControlStateNormal];
            roleControl.tag = 403;
            [cell.contentView addSubview:roleControl];
            
        }
        else {
            
            checkImageView.image = [UIImage imageNamed:@"unchecked.png"];
            checkImageView.alpha = .3;
            avatar.alpha = .3;
            cell.textLabel.alpha = .3;
        }
    }
    else {
        
        if (indexPath.row == self.inviteEmails.count+self.availableUsersDict.allKeys.count) {
            
            cell.textLabel.hidden = false;
            cell.textLabel.alpha = .3;
            cell.textLabel.text = @"Add new user to invite by email";
            
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
            if (![emailTest evaluateWithObject:inviteTextField.text]) inviteTextField.textColor = [UIColor redColor];
            inviteTextField.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
            [cell.contentView addSubview:inviteTextField];
            
            UIImageView *mailImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mail.png"]];
            mailImage.alpha = .3;
            mailImage.frame = CGRectMake(14, 6, 35, 35);
            mailImage.tag = 402;
            [cell.contentView addSubview:mailImage];
            
            UISegmentedControl *roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Viewer", @"Collaborator"]];
            roleControl.tintColor = [UIColor lightGrayColor];
            roleControl.center = CGPointMake(398, cell.frame.size.height/2);
            roleControl.selectedSegmentIndex = 1;
            [roleControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"SourceSansPro-Light" size:13]} forState:UIControlStateNormal];
            roleControl.tag = 403;
            [cell.contentView addSubview:roleControl];
            
            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setBackgroundImage:[UIImage imageNamed:@"minus2.png"] forState:UIControlStateNormal];
            deleteButton.frame = CGRectMake(485, 6, 35, 35);
            [deleteButton addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
            deleteButton.tag = 404;
            [cell.contentView addSubview:deleteButton];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [UIView setAnimationsEnabled:NO];
    
    [self updateInviteEmails];
    
    if (indexPath.row < self.availableUsersDict.allKeys.count) {
        
        NSString *userID = self.availableUsersDict.allKeys[indexPath.row];
        
        if ([self.selectedUsers containsObject:userID]) [self.selectedUsers removeObject:userID];
        else [self.selectedUsers addObject:userID];
        
        [self.usersTable reloadData];
    }
    else if (indexPath.row == self.inviteEmails.count+self.availableUsersDict.allKeys.count) {
        
        BOOL emptyCell = false;
        
        self.inviteEmails = [NSMutableArray array];
        
        for (int i=self.availableUsersDict.allKeys.count; i<self.usersTable.visibleCells.count-1; i++) {
            
            UITableViewCell *cell = self.usersTable.visibleCells[i];
            
            if ([cell.contentView viewWithTag:401]) {
                
                UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
                
                if ([textField isFirstResponder]) [textField resignFirstResponder];
                
                if (textField.text.length == 0) {
                    emptyCell = true;
                    [self.inviteEmails addObject:@""];
                }
                else [self.inviteEmails addObject:textField.text];
            }
        }
        
        if (!emptyCell) {
            
            [self.inviteEmails addObject:@""];
            [self.usersTable reloadData];
            UITableViewCell *newCell = self.usersTable.visibleCells[self.usersTable.visibleCells.count-2];
            [(UITextField *)[newCell.contentView viewWithTag:401] becomeFirstResponder];
            
        }
    }
    
    [UIView setAnimationsEnabled:YES];
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
