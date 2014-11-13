//
//  AvatarButton.h
//  chalk
//
//  Created by Alex Costantini on 10/13/14.
//  Copyright (c) 2014 chalk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AvatarButton : UIButton

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) UIImageView *drawingImage;
@property (strong, nonatomic) UIImageView *highlightedImage;

@end
