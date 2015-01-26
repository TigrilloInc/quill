//
//  TeamSettingsViewController.h
//  quill
//
//  Created by Alex Costantini on 1/25/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TeamSettingsViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate> {
    
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIButton *editNameButton;
@property (weak, nonatomic) IBOutlet UITextField *teamNameTextField;

@property (strong, nonatomic) NSMutableDictionary *usersDict;

@end
