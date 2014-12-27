//
//  AvatarButton.h
//  Quill
//
//  Created by Alex Costantini on 10/13/14.
//  Copyright (c) 2014 Tigrillo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IdenticonView.h"

@interface AvatarButton : UIButton

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) IdenticonView *identiconView;
@property (strong, nonatomic) UIImageView *drawingImage;
@property (strong, nonatomic) UIImageView *highlightedImage;

-(void) generateIdenticon;

@end
