//
//  InviteTableViewCell.h
//  quill
//
//  Created by Alex Costantini on 1/19/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UITextField *inviteField;
@property (weak, nonatomic) IBOutlet UISwitch *readOnlySwitch;
@property (weak, nonatomic) IBOutlet UILabel *readOnlyLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;


@end
