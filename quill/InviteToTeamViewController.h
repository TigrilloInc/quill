//
//  InviteToTeamViewController.h
//  quill
//
//  Created by Alex Costantini on 2/2/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface InviteToTeamViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource> {
    
    UIImageView *logoImage;
    ProjectDetailViewController *projectVC;
    NSMutableArray *editedText;
}

@property (weak, nonatomic) IBOutlet UITableView *inviteTable;
@property (strong, nonatomic) NSMutableArray *inviteEmails;
@property (strong, nonatomic) NSMutableDictionary *roles;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property (weak, nonatomic) IBOutlet RoundedButton *inviteButton;

@end
