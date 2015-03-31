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

@interface InviteToTeamViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate> {
    
    UIImageView *logoImage;
    ProjectDetailViewController *projectVC;
    NSMutableArray *editedText;
    NSMutableArray *teamEmails;
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property BOOL creatingTeam;
@property (weak, nonatomic) IBOutlet UITableView *inviteTable;
@property (strong, nonatomic) NSMutableArray *inviteEmails;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property (weak, nonatomic) IBOutlet RoundedButton *inviteButton;
@property (weak, nonatomic) IBOutlet UILabel *stepLabel;

@end
