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

@implementation InviteToTeamViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    self.inviteButton.layer.borderWidth = 1;
    self.inviteButton.layer.cornerRadius = 10;
    self.inviteButton.layer.borderColor = [UIColor grayColor].CGColor;
    
//    UIBarButtonItem *skipButton = [[UIBarButtonItem alloc]
//                                   initWithTitle: @"Skip"
//                                   style: UIBarButtonItemStyleBordered
//                                   target: nil action: nil];
//    [skipButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
//                                        [UIFont fontWithName:@"SourceSansPro-Semibold" size:16],NSFontAttributeName,
//                                        nil] forState:UIControlStateNormal];
//    [self.navigationItem setRightBarButtonItems:@[skipButton] animated:NO];
    
    self.inviteEmails = [NSMutableArray array];
    self.roles = [NSMutableDictionary dictionary];
    
    editedText = [NSMutableArray array];
    
    projectVC = (ProjectDetailViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    
    self.navigationItem.title = @"Step 3: Send Invites";
    
    [self.inviteEmails addObject:@""];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(144, 4, 35, 35);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
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

    int cellCount = self.inviteEmails.count;
    
    for (NSString *emailString in self.inviteEmails) {
        if (emailString.length == 0) [self.inviteEmails removeObject:emailString];
    }
    
    for (NSString *text in editedText) {
        [self.inviteEmails removeObject:text];
        [self.roles removeObjectForKey:text];
    }
    editedText = [NSMutableArray array];
    
    for (int i=0; i<cellCount; i++) {
        
        UITableViewCell *cell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
 
        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
        
        if (![self.inviteEmails containsObject:textField.text] && textField.text.length > 0) [self.inviteEmails addObject:textField.text];

        if (textField.text.length > 0 && [cell.contentView viewWithTag:403] != nil) {
            
            UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
            [self.roles setObject:@(roleControl.selectedSegmentIndex) forKey:textField.text];
        }
    }
}

-(void) roleTapped:(id)sender {
    
    UISegmentedControl *roleControl = (UISegmentedControl *)sender;
    UITableViewCell *cell = (UITableViewCell *)roleControl.superview.superview;
    
    UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
    [self.roles setObject:@(roleControl.selectedSegmentIndex) forKey:textField.text];
}

-(void) deleteTapped:(id)sender {
    
    [self updateInviteEmails];
    
    UIButton *deleteButton = (UIButton *)sender;
    NSString *emailString = ((UITextField *)[deleteButton.superview viewWithTag:401]).text;
    
    [self.inviteEmails removeObject:emailString];
    [self.roles removeObjectForKey:emailString];
    [self.inviteTable reloadData];
    
}

- (IBAction)sendTapped:(id)sender {

    [self updateInviteEmails];
    
    for (int i=0; i<self.inviteEmails.count; i++) {
        
        UITableViewCell *cell = [self.inviteTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:401];
        
        if ([textField isFirstResponder]) [textField resignFirstResponder];
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    NSMutableArray *errorEmails = [NSMutableArray array];
    
    for (NSString *emailString in self.inviteEmails) {
        
        if (![emailTest evaluateWithObject:emailString]) [errorEmails addObject:emailString];
    }
    
    if (errorEmails.count == 0) {
        
        self.inviteLabel.text =  @"Sending invites...";
        self.inviteButton.userInteractionEnabled = false;
        self.inviteButton.alpha = .5;

        if (self.inviteEmails.count > 0) {
            
            Firebase *tokenRef = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/tokens"];
            
            MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
            smtpSession.hostname = @"smtp.gmail.com";
            smtpSession.port = 465;
            smtpSession.username = @"cos@tigrillo.co";
            smtpSession.password = @"foothill94022";
            smtpSession.authType = MCOAuthTypeSASLPlain;
            smtpSession.connectionType = MCOConnectionTypeTLS;
            
            for (NSString *userEmail in self.inviteEmails) {
                
                NSString *token = [self generateToken];
                NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
                NSString *teamString = [NSString stringWithFormat:@"%@/team", token];
                NSString *projectString = [NSString stringWithFormat:@"%@/project/%@", token, [FirebaseHelper sharedHelper].currentProjectID];
                NSString *emailString = [NSString stringWithFormat:@"%@/email", token];
                NSString *invitedByString = [NSString stringWithFormat:@"%@/invitedBy", token];
                
                [[tokenRef childByAppendingPath:teamString] setValue:[FirebaseHelper sharedHelper].teamName];
                [[tokenRef childByAppendingPath:projectString] setValue:[self.roles objectForKey:userEmail]];
                [[tokenRef childByAppendingPath:emailString] setValue:userEmail];
                [[tokenRef childByAppendingPath:invitedByString] setValue:[FirebaseHelper sharedHelper].userName];
                
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
                        
                        self.inviteLabel.text = @"Invites Sent!";
                        [self performSelector:@selector(invitesSent) withObject:nil afterDelay:0.5];
                    }
                }];
            }
        }
        else {
            
            self.inviteLabel.text = @"Invites Sent!";
            [self performSelector:@selector(invitesSent) withObject:nil afterDelay:0.5];
        }
    }
    else {
        
        self.inviteLabel.text = @"Please fix the emails in red!";
    }
}

-(void) invitesSent {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Text field handling

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    textField.textColor = [UIColor blackColor];
    if (textField.text.length > 0) [editedText addObject:textField.text];
    
    UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    NSIndexPath *indexPath = [self.inviteTable indexPathForCell:cell];
    UISegmentedControl *roleControl = (UISegmentedControl *)[cell.contentView viewWithTag:403];
    UIButton *deleteButton = (UIButton *)[cell.contentView viewWithTag:404];
    roleControl.hidden = false;
    deleteButton.hidden = false;
    
    [self.inviteTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
        if (![emailTest evaluateWithObject:textField.text]) textField.textColor = [UIColor redColor];
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
        
        UISegmentedControl *roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Viewer", @"Collaborator"]];
        roleControl.tintColor = [UIColor lightGrayColor];
        roleControl.center = CGPointMake(398, cell.frame.size.height/2);
        int roleInt;
        if ([self.roles objectForKey:inviteTextField.text] == nil) roleInt = 1;
        else roleInt = [[self.roles objectForKey:inviteTextField.text] integerValue];
        roleControl.selectedSegmentIndex = roleInt;
        [roleControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"SourceSansPro-Light" size:13]} forState:UIControlStateNormal];
        [roleControl addTarget:self action:@selector(roleTapped:) forControlEvents:UIControlEventValueChanged];
        roleControl.tag = 403;
        [cell.contentView addSubview:roleControl];
        
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setBackgroundImage:[UIImage imageNamed:@"minus2.png"] forState:UIControlStateNormal];
        deleteButton.frame = CGRectMake(485, 7, 35, 35);
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
