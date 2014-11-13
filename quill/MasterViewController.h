//
//  MasterViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MasterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {

}

@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UITableView *projectsTable;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIButton *teamButton;
@property (strong, nonatomic) NSIndexPath *defaultRow;

@end
