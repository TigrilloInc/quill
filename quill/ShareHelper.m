//
//  ShareHelper.m
//  quill
//
//  Created by Alex Costantini on 6/16/15.
//  Copyright (c) 2015 chalk. All rights reserved.
//

#import "ShareHelper.h"

@implementation ShareHelper

static ShareHelper *sharedHelper = nil;

+ (ShareHelper *) sharedHelper {
    
    if (!sharedHelper) {
        
        sharedHelper = [[ShareHelper alloc] init];
        sharedHelper.slackToken = nil;
        sharedHelper.slackChannels = [NSMutableArray array];
    }
    
    return sharedHelper;
}


@end
