//
//  InviteTableViewCell.m
//  quill
//
//  Created by Alex Costantini on 1/19/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "InviteTableViewCell.h"
#import "InviteViewController.h"

@implementation InviteTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        self.textLabel.text = @"Add user to invite";
        self.indentationLevel = 4;
    }
    
    return self;
}

- (IBAction)deleteTapped:(id)sender {

//    InviteViewController *inviteVC = (InviteViewController *)self.superview.superview.superview.nextResponder;
//    
//    inviteVC.inviteEmails = [NSMutableArray array];
//    
//    for (int i=0; i<inviteVC.invitesTable.visibleCells.count-1; i++) {
//        
//        InviteTableViewCell *cell = (InviteTableViewCell *)inviteVC.invitesTable.visibleCells[i];
//        
//        NSLog(@"invite field text is %@", cell.inviteField.text);
//        
//        if (!cell.inviteField.text) [inviteVC.inviteEmails addObject:@""];
//        else [inviteVC.inviteEmails addObject:cell.inviteField.text];
//    }
//    
//    [inviteVC.inviteEmails removeObject:self.inviteField.text];
//    
//    NSLog(@"invite emails is %@", inviteVC.inviteEmails);
//    
//    [inviteVC.invitesTable reloadData];
}

@end
