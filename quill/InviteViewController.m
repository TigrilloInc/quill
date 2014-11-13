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

@interface InviteViewController ()

@end

@implementation InviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    inviteFields = @[self.inviteField1,self.inviteField2,self.inviteField3,self.inviteField4];
    
    for (UITextField *field in inviteFields) {
        field.placeholder = @"email";
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendTapped:(id)sender
{
    
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
    
    for (UITextField *textField in inviteFields) {
     
        if ([emailTest evaluateWithObject:textField.text] == true) {
            
            NSString *token = [self generateToken];
            NSString *tokenURL = [NSString stringWithFormat:@"chalk://%@", token];
            [ref updateChildValues:@{ token : [FirebaseHelper sharedHelper].teamName}];
            
            MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
            MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"cos@tigrillo.co"];
            MCOAddress *to = [MCOAddress addressWithDisplayName:nil mailbox:textField.text];
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
                    self.inviteLabel.text = @"Invites sent!";
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

@end
