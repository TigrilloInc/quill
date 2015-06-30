//
//  EmailBoardViewController.h
//  quill
//
//  Created by Alex Costantini on 5/21/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface EmailBoardViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource> {
    
    ProjectDetailViewController *projectVC;
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
