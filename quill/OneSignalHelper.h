//
//  OneSignalHelper.h
//  quill
//
//  Created by Alex Costantini on 3/1/16.
//  Copyright © 2016 chalk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OneSignal/OneSignal.h>

@interface OneSignalHelper : NSObject

+ (OneSignalHelper *) sharedHelper;
+ (void) sendPush:(NSMutableDictionary *)pushDict;

@property (strong, nonatomic) OneSignal *oneSignal;
@property BOOL registered;

@end
