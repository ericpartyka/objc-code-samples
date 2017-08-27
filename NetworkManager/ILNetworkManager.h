//
//  ILNetworkManager.h
//  Instalink
//
//  Created by Eric Partyka on 6/17/17.
//
//

#import <AFNetworking/AFNetworking.h>
#import "ILBlockDefine.h"

@interface ILNetworkManager : AFHTTPSessionManager

#pragma mark - Instance Methods

+ (instancetype)theManager;

+ (ILNetworkManager *)theSharedManager;

#pragma mark - API Functionality

+ (void)GET:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion;

+ (void)POST:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion;

+ (void)PUT:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion;

+ (void)DELETE:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion;

@end
