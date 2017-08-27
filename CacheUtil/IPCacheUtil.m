//
//  IPCacheUtil.m
//  InMotion Photos
//
//  Created by Eric Partyka on 8/20/17.
//  Copyright © 2017 SocialSell LLC. All rights reserved.
//

#import "IPCacheUtil.h"

@implementation IPCacheUtil

+ (NSString *)theAlbumsKey
{
    return @"albums";
}
    
+ (void)didCacheObject:(id)theObject withKey:(NSString *)theKey
{
    [[PINDiskCache sharedCache] setObject:theObject forKey:theKey];
}
    
+ (id)didGetObjectForKey:(NSString *)theKey
{
    id theObject = (id)[[PINDiskCache sharedCache] objectForKey:theKey];
    
    return theObject;
}
    
+ (void)didClearCache
{
    [[PINDiskCache sharedCache] removeAllObjects];
}
    
+ (BOOL)isObjectValidForKey:(NSString *)theKey
{
    id theObject = (id)[[PINDiskCache sharedCache] objectForKey:theKey];
    
    if (theObject == nil)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

    
@end
