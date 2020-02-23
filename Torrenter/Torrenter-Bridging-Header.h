//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "wrapper.h"

void torrent_initiate(const char*, const char*);
struct TorrentInfo torrent_get_info(int);
int torrent_count();
