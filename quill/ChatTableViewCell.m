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
        
        [CATransaction setDisableActions:YES];
        self.contentView.transform = CGAffineTransformMakeRotation(M_PI);
        [CATransaction setDisableActions:NO];
        
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.numberOfLines = 0;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

@end
