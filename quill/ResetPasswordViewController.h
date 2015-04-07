//
//  ResetPasswordViewController.h
//  quill
//
//  Created by Alex Costantini on 4/6/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface ResetPasswordViewController : UIViewController {
    
    UIImageView *logoImage;
}

@property (weak, nonatomic) IBOutlet UILabel *resetLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet RoundedButton *sendButton;

@end
