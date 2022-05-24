#include <stdbool.h>

void createCompatToolsInstance(const char *winePath, const char *wineDebugVars, bool esync);

void runInPrefix(const char *command);

void runInPrefixBlocking(const char *command);

void addRegistryKey(const char *key, const char *value, const char *data);

char *getProcessIds(const char *executableName);

void addEnviromentVariable(const char *key, const char *value);

void killWine(void);
