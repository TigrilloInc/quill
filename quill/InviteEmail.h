//
//  InviteEmail.h
//  quill
//
//  Created by Alex Costantini on 2/17/15.
//  Copyright (c) 2015 Tigrillo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InviteEmail : NSObject

@property (nonatomic, strong) NSString *inviteToken;
@property (nonatomic, strong) NSString *htmlBody;

-(void) updateHTML;

@end
