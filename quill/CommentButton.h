//
//  CommentButton.h
//  mailcore2
//
//  Created by Alex Costantini on 10/27/14.
//  Copyright (c) 2014 MailCore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IdenticonView.h"

@interface CommentButton : UIButton

@property CGPoint point;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *commentThreadID;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) IdenticonView *identiconView;
@property (strong, nonatomic) UIImageView *commentImage;
@property (strong, nonatomic) UIImageView *highlightedImage;
@property (strong, nonatomic) UIButton *deleteButton;
@property (strong, nonatomic) UILabel *commentTitleLabel;

-(void) generateIdenticon;
-(void) commentTapped;
-(void) updateLabel;

@end
