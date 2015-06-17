//
//  ShareHelper.h
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShareHelper : NSObject

@property (strong, nonatomic) NSString *slackToken;
@property (strong, nonatomic) NSMutableArray *slackChannels;

+ (ShareHelper *)sharedHelper;

@end
