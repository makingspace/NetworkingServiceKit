//
//  AbstractObjcBaseService.h
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/1/17.
//
//

#import <Foundation/Foundation.h>
#import <NetworkingServiceKit/NetworkingServiceKit-swift.h>

typedef void (^SuccessResponseBlock)(NSDictionary<NSString *,id> *response);
typedef void (^ErrorResponseBlock)(NSError *error);
@interface AbstractObjcBaseService : NSObject<AbstractService>

@end
