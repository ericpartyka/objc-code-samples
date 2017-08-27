//
//  ILNetworkManager.m
//  Instalink
//
//  Created by Eric Partyka on 6/17/17.
//
//

#import "ILNetworkManager.h"

@implementation ILNetworkManager

#pragma mark - Instance Methods

+ (instancetype)theManager
{
    static ILNetworkManager *theNetworkManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        theNetworkManager = [[self alloc] init];
        
    });
    
    return theNetworkManager;
}

+ (ILNetworkManager *)theSharedManager
{
    ILNetworkManager *theNetworkManager = [self theManager];
    
    return theNetworkManager;
}

#pragma mark - API Functionality

+ (void)GET:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion
{
    [[self theSharedManager] GET:theURLPath parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (completion) {
            completion(YES, nil, responseObject);
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion) {
            completion(NO, error, nil);
        }
        
    }];
}

+ (void)POST:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion
{
    [[self theSharedManager] POST:theURLPath parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    
        if (completion) {
            completion(YES, nil, responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       
        if (completion) {
            completion(NO, error, nil);
        }

    }];
}

+ (void)PUT:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion
{
    [[self theSharedManager] PUT:theURLPath parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (completion) {
            completion(YES, nil, responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion) {
            completion(NO, error, nil);
        }
        
    }];
}

+ (void)DELETE:(NSString *)theURLPath parameters:(id)parameters withCompletion:(MyCompletionBlockWithResponseObject)completion
{
    [[self theSharedManager] DELETE:theURLPath parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (completion) {
            completion(YES, nil, responseObject);
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion) {
            completion(NO, error, nil);
        }
        
    }];
}

@end
