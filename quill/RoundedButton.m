//
//  RoundedButton.m
//  quill
//
//  Created by Alex Costantini on 1/30/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "RoundedButton.h"

@implementation RoundedButton

- (void)setHighlighted:(BOOL)highlighted {
    
    [super setHighlighted:highlighted];
    
    if(self.highlighted) [self setAlpha:0.5];
    else [self setAlpha:1.0];

}


@end
