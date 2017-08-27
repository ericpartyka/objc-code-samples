//
//  IPAlbumStore.m
//  InMotion Photos
//
//  Created by Eric Partyka on 8/20/17.
//  Copyright © 2017 SocialSell LLC. All rights reserved.
//

#import "IPAlbumStore.h"
#import "IPNetworkManager.h"

@implementation IPAlbumStore

+ (NSString *)theAlbumsPath
{
    return @"http://jsonplaceholder.typicode.com/photos";
}
    
#pragma mark - GET
    
+ (void)didGetAlbumsWithCompletion:(MyCompletionBlock)completion
{
    [IPNetworkManager didGETWithURLPath:[self theAlbumsPath] andParameters:nil withCompletion:^(BOOL success, NSError *error, id responseObject) {
       
        if (success)
        {
            if (completion) {
                completion(YES, nil, responseObject);
            }
        }
        else
        {
            if (completion) {
                completion(NO, error, nil);
            }
        }
        
    }];
}
    
@end
