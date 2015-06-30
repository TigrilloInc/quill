//
//  TransferOwnerViewController.h
//  quill
//
//  Created by Alex Costantini on 2/19/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface TransferOwnerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    
    ProjectDetailViewController *projectVC;
}

@property (strong, nonatomic) NSDictionary *availableUsersDict;
@property (strong, nonatomic) NSString *selectedUserID;
@property (weak, nonatomic) IBOutlet RoundedButton *ownerButton;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;

@end
