//
//  AvatarButton.m
//  Quill
//
//  Created by Alex Costantini on 10/13/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "AvatarButton.h"

@implementation AvatarButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userImage = [UIImage imageNamed:@"user.png"];
        [self setImage:self.userImage forState:UIControlStateNormal];
        
        self.drawingImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"drawing.png"]];
        self.drawingImage.hidden = true;
        [self addSubview:self.drawingImage];
        
        self.highlightedImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userhighlight.png"]];
        self.highlightedImage.hidden = true;
        self.highlightedImage.center = self.drawingImage.center;
        [self addSubview:self.highlightedImage];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
