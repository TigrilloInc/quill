//
//  InviteViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteViewController : UIViewController {
    
    NSArray *inviteFields;
}

@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property (weak, nonatomic) IBOutlet UITextField *inviteField1;
@property (weak, nonatomic) IBOutlet UITextField *inviteField2;
@property (weak, nonatomic) IBOutlet UITextField *inviteField3;
@property (weak, nonatomic) IBOutlet UITextField *inviteField4;

@end
