//
//  AbstractObjcBaseService.m
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/1/17.
//
//

#import "AbstractObjcBaseService.h"

@implementation AbstractObjcBaseService
@synthesize token;
@synthesize networkManager;

-(instancetype)initWithToken:(APIToken *)newToken networkManager:(id<NetworkManager>)newNetworkManager
{
    if(self = [super init])
    {
        self.token = newToken;
        self.networkManager = newNetworkManager;
    }
    return self;
}

-(APIConfiguration *)currentConfiguration
{
    return self.networkManager.configuration;
}

-(NSString *)servicePath
{
    return @"";
}
-(NSString *)serviceVersion
{
    return @"v3";
}

-(NSString *)servicePathFor:(NSString *)query
{
    NSString *fullPath = @"";
    if (self.servicePath) {
        fullPath = [fullPath stringByAppendingPathComponent:self.servicePath];
    }
    if (self.serviceVersion) {
        fullPath = [fullPath stringByAppendingPathComponent:self.serviceVersion];
    }
    if (query) {
        fullPath = [fullPath stringByAppendingPathComponent:query];
    }
    return fullPath;
}

-(BOOL)isAuthenticated
{
    return self.token != nil;
}


/**
 Creates and executes a request using our current Network provider

 @param path full path to the URL
 @param method HTTP method, default is GET
 @param parameters URL or body parameters depending on the HTTP method, default is empty
 @param paginated if the request should follow pagination, success only if all pages are completed
 @param success success block with a response
 @param failure failure block with an error
 */
-(void)requestWithPath:(NSString *)path
                method:(enum HTTPMethod)method
                  with:(NSDictionary<NSString *,id> *)parameters
             paginated:(BOOL)paginated
               success:(void (^)(NSDictionary<NSString *,id> * _Nonnull))success
               failure:(void (^)(NSError * _Nonnull, NSDictionary<NSString *,id> * _Nonnull))failure
{
    [self.networkManager requestWithPath:path method:method with:parameters paginated:paginated success:success failure:failure];
}

@end
