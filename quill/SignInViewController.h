//
//  SignInViewController.h
//  chalk
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SignInViewController : UIViewController <UITextFieldDelegate> {
    
    BOOL _signingIn;
}


@property (weak, nonatomic) IBOutlet UILabel *signInLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UIButton *passwordResetButton;


@end
