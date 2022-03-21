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

- (instancetype)initWithAppId: (long)appId {
    if (self = [super init]) {
        _appStr = (char*) malloc((22)*sizeof(char));
        _gameStr = (char*) malloc((23)*sizeof(char));
        sprintf(_appStr, "SteamAppId=%ld", appId);
        sprintf(_gameStr, "SteamGameId=%ld", appId);
        putenv(_appStr);
        putenv(_gameStr);
        _initSuccess = SteamAPI_Init();
    }
    return self;
}

- (void)reinitWithAppId: (long)appId {
    SteamAPI_Shutdown();
    sprintf(_appStr, "SteamAppId=%ld", appId);
    sprintf(_gameStr, "SteamGameId=%ld", appId);
    putenv(_appStr);
    putenv(_gameStr);
    _initSuccess = SteamAPI_Init();
}

- (void)dealloc {
    SteamAPI_Shutdown();
    free(_appStr);
    free(_gameStr);
}

- (NSData *)authSessionTicket {
    if (!_initSuccess) {
        putenv(_appStr);
        putenv(_gameStr);
        if (!(_initSuccess = SteamAPI_Init())) {
            return NULL;
        }
    }
    HAuthTicket m_hAuthTicket;
    char rgchToken[1024];
    uint32 unTokenLen = 0;
    m_hAuthTicket = SteamUser()->GetAuthSessionTicket( rgchToken, sizeof( rgchToken ), &unTokenLen );
    if ( unTokenLen < 1 )
        return NULL;
    return [NSData dataWithBytes:rgchToken length:unTokenLen];
}

- (uint32)serverRealTime {
    if (!_initSuccess)
        return 0;
    return SteamUtils()->GetServerRealTime();
}

@end
