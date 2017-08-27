//
//  IPAlbumStore.h
//  InMotion Photos
//
//  Created by Eric Partyka on 8/20/17.
//  Copyright © 2017 SocialSell LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPBlockConst.h"

@interface IPAlbumStore : NSObject

#pragma mark - GET
    
+ (void)didGetAlbumsWithCompletion:(MyCompletionBlock)completion;
    
@end
