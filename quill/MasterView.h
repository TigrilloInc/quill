//
//  MasterView.h
//  Quill
//
//  Created by Alex Costantini on 7/9/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AvatarButton.h"

@class ProjectDetailViewController;

@interface MasterView : UIView <UITableViewDelegate, UITableViewDataSource> {
    
    ProjectDetailViewController *projectVC;
}

@property (weak, nonatomic) IBOutlet UITableView *projectsTable;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIButton *teamButton;
@property (weak, nonatomic) IBOutlet UIButton *teamMenuButton;
@property (strong, nonatomic) AvatarButton *avatarButton;
@property (strong, nonatomic) NSIndexPath *defaultRow;
@property (strong, nonatomic) NSArray *orderedProjectNames;

-(void)updateProjects;
-(IBAction)settingsTapped:(id)sender;

@end