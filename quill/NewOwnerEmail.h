//
//  NewOwnerEmail.h
//  quill
//
//  Created by Alex Costantini on 3/26/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewOwnerEmail : NSObject

@property (nonatomic, strong) NSString *inviteURL;
@property (nonatomic, strong) NSString *htmlBody;

-(void) updateHTML;

@end
