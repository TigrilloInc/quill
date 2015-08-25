//
//  SignInViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface SignInViewController : UIViewController <UITextFieldDelegate> {
    
    UIImageView *logoImage;
    BOOL termsChecked;
}

@property BOOL signingIn;
@property (weak, nonatomic) IBOutlet UILabel *signInLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet RoundedButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UIButton *passwordResetButton;
@property (weak, nonatomic) IBOutlet UIButton *termsButton;
@property (weak, nonatomic) IBOutlet UILabel *termsLabel;
@property (weak, nonatomic) IBOutlet UIButton *termsLink;
@property (weak, nonatomic) IBOutlet UIButton *privacyLink;


-(void) accountCreated;
-(void) showLogo;

@end
