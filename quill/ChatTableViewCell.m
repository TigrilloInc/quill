//
//  ChatTableViewCell.m
//  quill
//
//  Created by Alex Costantini on 11/20/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "ChatTableViewCell.h"

@implementation ChatTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        [UIView setAnimationsEnabled:NO];
        [CATransaction setDisableActions:YES];
        
        self.contentView.transform = CGAffineTransformMakeRotation(M_PI);
        
        [UIView setAnimationsEnabled:YES];
        [CATransaction setDisableActions:NO];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

@end
