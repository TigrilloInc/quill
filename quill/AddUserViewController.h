//
//  AddUserViewController.h
//  Quill
//
//  Created by Alex Costantini on 10/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface AddUserViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate> {

    ProjectDetailViewController *projectVC;
    UITapGestureRecognizer *outsideTapRecognizer;
    NSMutableArray *teamEmails;
    NSMutableArray *editedText;
}

@property (strong, nonatomic) IBOutlet UITableView *usersTable;
@property (strong, nonatomic) NSDictionary *availableUsersDict;
@property (strong, nonatomic) NSMutableArray *selectedUsers;
@property (strong, nonatomic) NSMutableArray *inviteEmails;
@property (strong, nonatomic) NSMutableDictionary *roles;
@property (weak, nonatomic) IBOutlet RoundedButton *inviteButton;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;


@end
