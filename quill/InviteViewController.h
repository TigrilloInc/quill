//
//  InviteViewController.h
//  Quill
//
//  Created by Alex Costantini on 7/18/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteViewController : UIViewController <UIGestureRecognizerDelegate> {
    
    UITapGestureRecognizer *outsideTapRecognizer;
}

@property (strong, nonatomic) NSMutableArray *inviteEmails;
@property (strong, nonatomic) IBOutlet UILabel *inviteLabel;
@property (strong, nonatomic) IBOutlet UITableView *invitesTable;

@end
