//
//  ChatTableViewCell.m
//  quill
//
//  Created by Alex Costantini on 11/20/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "ChatTableViewCell.h"

@implementation ChatTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        [UIView setAnimationsEnabled:NO];
        [CATransaction setDisableActions:YES];
        
        self.contentView.transform = CGAffineTransformMakeRotation(M_PI);
        
//        self.avatar = [AvatarButton buttonWithType:UIButtonTypeCustom];
//        self.avatar.transform = CGAffineTransformMakeScale(.16, .16);
//        self.avatar.userInteractionEnabled = false;
//        [self.contentView addSubview:self.avatar];
//        
//        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//        nameLabel.font = [UIFont fontWithName:@"SourceSansPro-Regular" size:14];
//        [self.contentView addSubview:self.nameLabel];
//        
//        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//        self.dateLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:12];
//        [self.contentView addSubview:dateLabel];
//
//
//        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//        self.messageLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
//        [self.contentView addSubview:self.messageLabel];
        
        [UIView setAnimationsEnabled:YES];
        [CATransaction setDisableActions:NO];
        
//        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
//        self.textLabel.numberOfLines = 0;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

@end
