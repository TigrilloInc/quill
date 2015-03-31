//
//  ProjectsTableViewCell.m
//  quill
//
//  Created by Alex Costantini on 12/15/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "ProjectsTableViewCell.h"

@implementation ProjectsTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {

        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.textLabel.font = [UIFont fontWithName:@"SourceSansPro-Light" size:20];
        self.shadowImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"projectsshadow.png"]];
        [self.backgroundView addSubview:self.shadowImage];
    }
    
    return self;
}

@end
