//
//  DrawView.m
//  quill
//
//  Created by Alex Costantini on 12/22/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import "DrawView.h"

@implementation DrawView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
    
        self.paths = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    // clear rect
    [self.backgroundColor set];
    UIRectFill(rect);

    // get the graphics context and draw the path
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    
    for (NSDictionary *subpathValues in self.paths) {
        
        CGMutablePathRef subpath = CGPathCreateMutable();
        CGPathMoveToPoint(subpath, NULL, [[subpathValues objectForKey:@"mid1x"] floatValue], [[subpathValues objectForKey:@"mid1y"] floatValue]);
        CGPathAddQuadCurveToPoint(subpath, NULL,
                                  [[subpathValues objectForKey:@"prevx"] floatValue], [[subpathValues objectForKey:@"prevy"] floatValue],
                                  [[subpathValues objectForKey:@"mid2x"] floatValue], [[subpathValues objectForKey:@"mid2y"] floatValue]);
        CGContextAddPath(context, subpath);
        
        int colorNumber = [[subpathValues objectForKey:@"color"] intValue];
        UIColor *lineColor;
        
        if (colorNumber == 0) lineColor = [UIColor whiteColor];
        if (colorNumber == 1) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(220.0f/255.0f) green:(220.0f/255.0f) blue:(220.0f/255.0f) alpha:1.0f];
            else lineColor = [UIColor blackColor];
        }
        if (colorNumber == 2) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(200.0f/255.0f) green:(230.0f/255.0f) blue:1.0f alpha:1.0f];
            else lineColor = [UIColor colorWithRed:0.0f green:(60.0f/255.0f) blue:1.0f alpha:1.0f];
        }
        if (colorNumber == 3) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:1.0f green:(200.0f/255.0f) blue:(200.0f/255.0f) alpha:1.0f];
            else lineColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f];
        }
        if (colorNumber == 4) {
            if  ([subpathValues objectForKey:@"faded"]) lineColor = [UIColor colorWithRed:(230.0f/255.0f) green:1.0f blue:(200.0f/255.0f) alpha:1.0f];
            else lineColor = [UIColor colorWithRed:(60.0f/255.0f) green:1.0f blue:0.0f alpha:1.0f];
        }
        
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextSetLineWidth(context, [[subpathValues objectForKey:@"width"] floatValue]);
        CGContextStrokePath(context);
        CGContextBeginPath(context);
    }
}

@end
