//
//  InviteToTeamViewController.h
//  quill
//
//  Created by Alex Costantini on 2/2/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProjectDetailViewController.h"
#import "RoundedButton.h"

@interface InviteToTeamViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource> {
    
    BOOL invitesSent;
    NSInteger inviteCount;
    
    UIImageView *logoImage;
    ProjectDetailViewController *projectVC;
    NSMutableArray *editedText;
    NSMutableArray *teamEmails;
}

@property BOOL creatingTeam;
@property (strong, nonatomic) IBOutlet UITableView *inviteTable;
@property (strong, nonatomic) NSMutableArray *inviteEmails;
@property (strong, nonatomic) IBOutlet UILabel *inviteLabel;
@property (strong, nonatomic) IBOutlet RoundedButton *inviteButton;
@property (strong, nonatomic) IBOutlet UILabel *stepLabel;
@property (strong, nonatomic) IBOutlet UIImageView *inviteFade;

@end
