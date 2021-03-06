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

@property (strong, nonatomic) IBOutlet UITableView *projectsTable;
@property (strong, nonatomic) IBOutlet UIButton *nameButton;
@property (strong, nonatomic) IBOutlet UIButton *teamButton;
@property (strong, nonatomic) IBOutlet UIButton *teamMenuButton;
@property (strong, nonatomic) AvatarButton *avatarButton;
@property (strong, nonatomic) NSIndexPath *defaultRow;
@property (strong, nonatomic) NSArray *orderedProjectNames;
@property (strong, nonatomic) UIImageView *avatarShadow;

-(void)updateProjects;
-(IBAction)settingsTapped:(id)sender;

@end