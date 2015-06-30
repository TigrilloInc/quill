//
//  SignedOutAlertViewController.m
//  quill
//
//  Created by Alex Costantini on 3/30/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import "SignedOutAlertViewController.h"
#import "FirebaseHelper.h"
#import "SignInViewController.h"

@implementation SignedOutAlertViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.title = @"User Signed Out";
    
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.cornerRadius = 10;
    self.okButton.layer.borderColor = [UIColor grayColor].CGColor;
}

- (void)viewWillAppear:(BOOL)animated {
    
    UIFont *emailFont = [UIFont fontWithName:@"SourceSansPro-Semibold" size:20];
    UIFont *labelFont = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
    NSDictionary *emailAttrs = [NSDictionary dictionaryWithObjectsAndKeys: emailFont, NSFontAttributeName, nil];
    NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys: labelFont, NSFontAttributeName, nil];
    
    NSString *signedOutString = [NSString stringWithFormat:@"You've been signed out because the email %@ has been used to sign into a different device.", self.email];
    NSMutableAttributedString *signedOutAttrString = [[NSMutableAttributedString alloc] initWithString:signedOutString attributes:labelAttrs];
    [signedOutAttrString setAttributes:emailAttrs range:NSMakeRange(41,self.email.length)];
    [self.signedOutLabel setAttributedText:signedOutAttrString];
    
}

- (IBAction)okTapped:(id)sender {
    
    SignInViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SignIn"];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
    logoImageView.frame = CGRectMake(155, 8, 32, 32);
    logoImageView.tag = 800;
    [nav.navigationBar addSubview:logoImageView];
    
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:nav animated:YES completion:nil];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:nav animated:YES completion:nil];
    }];
}

@end
