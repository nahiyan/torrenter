//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "wrapper.h"

void torrent_initiate(const char*, const char*);
struct Torrent torrent_get(int);
int torrent_count();
