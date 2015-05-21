//
//  BoardEmail.h
//  quill
//
//  Created by Alex Costantini on 5/21/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BoardEmail : NSObject

@property (nonatomic, strong) NSString *htmlBody;

-(void) updateHTML;

@end
