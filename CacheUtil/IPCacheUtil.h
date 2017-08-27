//
//  IPCacheUtil.h
//  InMotion Photos
//
//  Created by Eric Partyka on 8/20/17.
//  Copyright © 2017 SocialSell LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PINCache/PINDiskCache.h>

@interface IPCacheUtil : NSObject

+ (NSString *)theAlbumsKey;
    
+ (void)didCacheObject:(id)theObject withKey:(NSString *)theKey;
    
+ (id)didGetObjectForKey:(NSString *)theKey;
    
+ (void)didClearCache;
    
+ (BOOL)isObjectValidForKey:(NSString *)theKey;
    
@end
