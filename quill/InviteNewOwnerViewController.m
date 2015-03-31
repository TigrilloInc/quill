//
//  InviteNewOwnerViewController.m
//  quill
//
//  Created by Alex Costantini on 3/26/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "InviteNewOwnerViewController.h"
#import "FirebaseHelper.h"
#import <MailCore/mailcore.h>
#import "NewOwnerEmail.h"

@implementation InviteNewOwnerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"Invite New Team Owner";
    
    logoImage = (UIImageView *)[self.navigationController.navigationBar viewWithTag:800];
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [self.emailTextField setLeftViewMode:UITextFieldViewModeAlways];
    [self.emailTextField setLeftView:spacerView];
    self.emailTextField.layer.borderColor = [UIColor groupTableViewBackgroundColor].CGColor;
    self.emailTextField.layer.borderWidth = 1;
    self.emailTextField.layer.cornerRadius = 10;

    self.sendButton.layer.borderWidth = 1;
    self.sendButton.layer.cornerRadius = 10;
    self.sendButton.layer.borderColor = [UIColor grayColor].CGColor;
}

-(void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutside)];
    
    [outsideTapRecognizer setDelegate:self];
    [outsideTapRecognizer setNumberOfTapsRequired:1];
    outsideTapRecognizer.cancelsTouchesInView = NO;
    [self.view.window addGestureRecognizer:outsideTapRecognizer];
}

-(void) viewWillDisappear:(BOOL)animated {
    
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        
        logoImage.hidden = true;
        logoImage.frame = CGRectMake(173, 8, 32, 32);
        
        [self performSelector:@selector(showLogo) withObject:nil afterDelay:.3];
    }
    
    self.emailTextField.delegate = nil;

    
    outsideTapRecognizer.delegate = nil;
    [self.view.window removeGestureRecognizer:outsideTapRecognizer];
    
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

- (IBAction)sendTapped:(id)sender {
    
    if (self.emailTextField.text.length == 0) {
        
        self.inviteLabel.text = @"Please enter an email.";
        return;
    }
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];

    if (![emailTest evaluateWithObject:self.emailTextField.text]) {
    
        self.inviteLabel.text = @"Please enter a valid email.";
        return;
    }
    
    self.inviteLabel.text = @"Sending invite...";
    
    self.emailTextField.userInteractionEnabled = false;
    self.emailTextField.alpha = .5;
    self.sendButton.userInteractionEnabled = false;
    self.sendButton.alpha = .5;
    
    NSString *token = [self generateToken];
    NSString *tokenURL = [NSString stringWithFormat:@"quill://%@", token];
    
    NSString *tokenString = [NSString stringWithFormat:@"https://chalkto.firebaseio.com/tokens/%@", token];
    Firebase *tokenRef = [[Firebase alloc] initWithUrl:tokenString];
    
    [tokenRef setValue:@{ @"newOwner" : self.emailTextField.text }];
    
    MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
    MCOAddress *from = [MCOAddress addressWithDisplayName:@"Quill" mailbox:@"cos@tigrillo.co"];
    MCOAddress *to = [MCOAddress addressWithDisplayName:nil mailbox:self.emailTextField.text];
    [[builder header] setFrom:from];
    [[builder header] setTo:@[to]];
    [[builder header] setSubject:@"Welcome to Quill!"];
    
    NewOwnerEmail *inviteEmail = [[NewOwnerEmail alloc] init];
    inviteEmail.inviteURL = tokenURL;
    [inviteEmail updateHTML];
    [builder setHTMLBody:inviteEmail.htmlBody];

    //[builder setTextBody:tokenURL];
    NSData * rfc822Data = [builder data];
    
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.hostname = @"smtp.gmail.com";
    smtpSession.port = 465;
    smtpSession.username = @"hello@tigrillo.co";
    smtpSession.password = @"DRc4iK3NJZ;aKEodNoH/";
    smtpSession.authType = MCOAuthTypeSASLPlain;
    smtpSession.connectionType = MCOConnectionTypeTLS;
    
    MCOSMTPSendOperation *sendOperation =
    [smtpSession sendOperationWithData:rfc822Data];
    [sendOperation start:^(NSError *error) {
        if(error) {
            
            NSLog(@"Error sending email: %@", error);
            
            self.inviteLabel.text = @"Something went wrong - try again.";
            
            self.emailTextField.userInteractionEnabled = true;
            self.emailTextField.alpha = 1;
            self.sendButton.userInteractionEnabled = true;
            self.sendButton.alpha = 1;
        }
        else {
            
            self.inviteLabel.text = @"Invites sent!";
            [self performSelector:@selector(dismiss) withObject:nil afterDelay:.3];
        }
    }];
}


-(void) dismiss {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
