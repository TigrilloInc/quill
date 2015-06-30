//
//  IdenticonView.m
//  quill
//
//  Created by Alex Costantini on 12/16/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import "IdenticonView.h"

@implementation IdenticonView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    return NO;
}

- (void)drawRect:(CGRect)rect {
    
    int verticalOffset = 0;
    int horizontalOffset = 0;
    int squareSize = self.frame.size.width/5;

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (int i = 1; i <= self.tileValues.count; i++) {
        
        CGRect square = {horizontalOffset, verticalOffset, squareSize, squareSize};
        
        if ([[self.tileValues objectAtIndex:i-1] integerValue] > 4) CGContextSetRGBFillColor(context, self.tileColor.red, self.tileColor.green, self.tileColor.blue, 1);
        else CGContextSetRGBFillColor(context, 1, 1, 1, 0);
        
        CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
        
        CGContextFillRect(context, square);
        CGContextStrokeRect(context, square);
        
        horizontalOffset = horizontalOffset + squareSize;
        if (i % 5 == 0) {
            verticalOffset = verticalOffset + squareSize;
            horizontalOffset = 0;
        }
    }
}

@end
