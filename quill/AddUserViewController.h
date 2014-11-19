//
//  AddUserViewController.h
//  Quill
//
//  Created by Alex Costantini on 10/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"

@interface AddUserViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate> {

    ProjectDetailViewController *projectVC;
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property (weak, nonatomic) IBOutlet UISwitch *roleSwitch;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;
@property (strong, nonatomic) NSDictionary *availableUsersDict;
@property (strong, nonatomic) NSMutableArray *selectedUsers;


@end
