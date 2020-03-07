//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "wrapper.h"

void torrent_initiate(const char*, const char*, bool);
void torrent_initiate_magnet_uri(const char*, const char*, bool);
struct TorrentInfo torrent_get_info(int);
int torrent_count();
void torrent_pause(int);
void torrent_flags(int);
void torrent_resume(int);
bool torrent_is_paused(int);
