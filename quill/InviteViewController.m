//
//  InviteViewController.m
//  Quill
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "InviteViewController.h"
#import <Firebase/Firebase.h>
#import "FirebaseHelper.h"
#import <MailCore/mailcore.h>
#import "InviteTableViewCell.h"

@implementation InviteViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.inviteEmails = [NSMutableArray array];
    [self.inviteEmails addObject:@""];
}

- (void) viewDidAppear:(BOOL)animated {
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) addInviteTapped {
    
    
}

- (IBAction)sendTapped:(id)sender {
    
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://chalkto.firebaseio.com/tokens"];
    
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.hostname = @"smtp.gmail.com";
    smtpSession.port = 465;
    smtpSession.username = @"cos@tigrillo.co";
    smtpSession.password = @"foothill94022";
    smtpSession.authType = MCOAuthTypeSASLPlain;
    smtpSession.connectionType = MCOConnectionTypeTLS;
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    for (InviteTableViewCell *cell in self.invitesTable.visibleCells) {
     
        NSString *emailString = ((UITextField *)[cell.contentView viewWithTag:301]).text;
        
        if ([emailTest evaluateWithObject:emailString] == true) {
            
            NSString *token = [self generateToken];
            NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
            [ref updateChildValues:@{ token : [FirebaseHelper sharedHelper].teamName}];
            
            MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
            MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"cos@tigrillo.co"];
            MCOAddress *to = [MCOAddress addressWithDisplayName:nil mailbox:emailString];
            [[builder header] setFrom:from];
            [[builder header] setTo:@[to]];
            
            [[builder header] setSubject:@"Welcome to Quill!"];
            //[builder setHTMLBody:@""];
            [builder setTextBody:tokenURL];
            NSData * rfc822Data = [builder data];
            
            MCOSMTPSendOperation *sendOperation =
            [smtpSession sendOperationWithData:rfc822Data];
            [sendOperation start:^(NSError *error) {
                if(error) {
                    NSLog(@"Error sending email: %@", error);
                } else {
 //                   self.inviteLabel.text = @"Invites sent!";
                    NSLog(@"Successfully sent email!");
                }
            }];
        }
    }
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

-(void) tappedOutside {
    
    if (outsideTapRecognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint location = [outsideTapRecognizer locationInView:nil];
        CGPoint converted = [self.view convertPoint:CGPointMake(1024-location.y,location.x) fromView:self.view.window];
        
        if (!CGRectContainsPoint(self.view.frame, converted)){
            
            [outsideTapRecognizer setDelegate:nil];
            [self.view.window removeGestureRecognizer:outsideTapRecognizer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(void) deleteTapped:(id)sender {
    
    self.inviteEmails = [NSMutableArray array];
    
    for (int i=0; i<self.invitesTable.visibleCells.count-1; i++) {
        
        InviteTableViewCell *cell = (InviteTableViewCell *)self.invitesTable.visibleCells[i];
        
        if ([cell.contentView viewWithTag:301]) {
            
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:301];
            
            if (textField.text.length == 0) [self.inviteEmails addObject:@""];
            else [self.inviteEmails addObject:textField.text];
        }
    }
    
    UIButton *deleteButton = (UIButton *)sender;
    NSString *emailString = ((UITextField *)[deleteButton.superview viewWithTag:301]).text;
    
    [self.inviteEmails removeObject:emailString];
    if (self.inviteEmails.count == 0) [self.inviteEmails addObject:@""];
    [self.invitesTable reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.inviteEmails.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    InviteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InviteCell" forIndexPath:indexPath];

    for (int i=1; i<6; i++) {
        
        if ([cell.contentView viewWithTag:300+i]) [[cell.contentView viewWithTag:300+i] removeFromSuperview];
    }
    
    if (indexPath.row == self.inviteEmails.count) {
        
        cell.textLabel.hidden = false;

        
        UIImageView *plusImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus3.png"]];
        plusImage.frame = CGRectMake(14, 7, 30, 30);
        plusImage.tag = 305;
        [cell.contentView addSubview:plusImage];
        
//        cell.textLabel.hidden = false;
//        cell.inviteField.hidden = true;
//        cell.readOnlyLabel.hidden = true;
//        cell.readOnlySwitch.hidden = true;
//        cell.deleteButton.hidden = true;
    }
    else {
        
        cell.textLabel.hidden = true;
        
        UITextField *inviteTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 2, 248, 42)];
        inviteTextField.placeholder = @"Enter Email";
        inviteTextField.tag = 301;
        inviteTextField.text = self.inviteEmails[indexPath.row];
        [cell.contentView addSubview:inviteTextField];

        UILabel *readOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(320, 11, 82, 21)];
        readOnlyLabel.text = @"Read-Only";
        readOnlyLabel.tag = 302;
        [cell.contentView addSubview:readOnlyLabel];
        
        UISwitch *readOnlySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(410, 6, 51, 31)];
        readOnlySwitch.tag = 303;
        [cell.contentView addSubview:readOnlySwitch];
        
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deleteButton setBackgroundImage:[UIImage imageNamed:@"minus2.png"] forState:UIControlStateNormal];
        deleteButton.frame = CGRectMake(485, 7, 30, 30);
        [deleteButton addTarget:self action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
        deleteButton.tag = 304;
        [cell.contentView addSubview:deleteButton];
        
//        cell.textLabel.hidden = true;
//        cell.inviteField.hidden = false;
//        cell.readOnlyLabel.hidden = false;
//        cell.readOnlySwitch.hidden = false;
//        cell.deleteButton.hidden = false;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == self.inviteEmails.count) {
        
        BOOL emptyCell = false;
        self.inviteEmails = [NSMutableArray array];
        
        for (InviteTableViewCell *cell in self.invitesTable.visibleCells) {
            
            if ([cell.contentView viewWithTag:301]) {
            
                UITextField *textField = (UITextField *)[cell.contentView viewWithTag:301];
                
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
            [self.invitesTable reloadData];
        
            InviteTableViewCell *newCell = (InviteTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            [(UITextField *)[newCell.contentView viewWithTag:301] becomeFirstResponder];
        }
        
//        BOOL emptyCell = false;
//        
//        for (int i=0; i<self.invitesTable.visibleCells.count-1; i++) {
//            
//            InviteTableViewCell *cell = (InviteTableViewCell *)self.invitesTable.visibleCells[i];
//            
//            if ([cell.inviteField isFirstResponder]) [cell.inviteField resignFirstResponder];
//            
//            NSLog(@"cell length is %i", cell.inviteField.text.length);
//            if (cell.inviteField.text.length == 0) emptyCell = true;
//        }
//
//        if (!emptyCell) {
//            
//            [self.inviteEmails insertObject:@"" atIndex:0];
//            [self.invitesTable reloadData];
//            
//            InviteTableViewCell *cell = (InviteTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"InviteCell" forIndexPath:indexPath];
//            [cell.inviteField becomeFirstResponder];
//        }
    }
    
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
