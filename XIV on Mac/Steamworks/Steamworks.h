//
//  Steamworks.h
//  
//
//  Created by Marc-Aurel Zent on 08.03.22.
//

#ifndef Header_h
#define Header_h
#import <Foundation/Foundation.h>

@interface Steamworks : NSObject
@property (readonly, copy) NSData *authSessionTicket;
@property (readonly) uint32 serverRealTime;
@property (readonly) bool initSuccess;
@property (readonly) char *appStr;
@property (readonly) char *gameStr;

- (instancetype)initWithAppId: (long)appId;
- (void)reinitWithAppId: (long)appId;

@end

#endif /* Header_h */
