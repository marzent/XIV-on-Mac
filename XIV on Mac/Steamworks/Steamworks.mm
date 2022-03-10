//
//  Steamworks.mm
//  
//
//  Created by Marc-Aurel Zent on 08.03.22.
//

#include <cstdlib>
#include <iostream>
#include "Headers/steam_api.h"
#include "Steamworks.h"

@implementation Steamworks : NSObject

- (id)init {
    if (self = [super init]) {
        SteamAPI_Init();
    }
    return self;
}

- (void)dealloc {
    SteamAPI_Shutdown();
}

- (NSData *)authSessionTicket {
    HAuthTicket m_hAuthTicket;
    char rgchToken[1024];
    uint32 unTokenLen = 0;
    m_hAuthTicket = SteamUser()->GetAuthSessionTicket( rgchToken, sizeof( rgchToken ), &unTokenLen );
    if ( unTokenLen < 1 )
        return NULL;
    return [NSData dataWithBytes:rgchToken length:unTokenLen];
}

- (uint32)serverRealTime {
    return SteamUtils()->GetServerRealTime();
}

@end
