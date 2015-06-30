//
//  InviteNewOwnerViewController.h
//  quill
//
//  Created by Alex Costantini on 3/26/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedButton.h"

@interface InviteNewOwnerViewController : UIViewController {
    
    UIImageView *logoImage;
}

@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet RoundedButton *sendButton;

@end
