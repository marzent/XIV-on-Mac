#include <stdbool.h>

void createCompatToolsInstance(const char *winePath, const char *wineDebugVars, bool esync);

void runInPrefix(const char *command, bool blocking, bool wineD3D);

void ensurePrefix();

void addRegistryKey(const char *key, const char *value, const char *data);

char *getProcessIds(const char *executableName);

void addEnvironmentVariable(const char *key, const char *value);

void killWine(void);
