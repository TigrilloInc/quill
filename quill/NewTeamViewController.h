//
//  NewTeamViewController.h
//  chalk
//
//  Created by Alex Costantini on 7/7/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewTeamViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *teamField;
@property (weak, nonatomic) IBOutlet UIButton *createTeamButton;

@end
