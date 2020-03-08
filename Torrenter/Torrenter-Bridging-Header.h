//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "wrapper.h"

int torrent_initiate(const char *, const char *, bool);
int torrent_initiate_magnet_uri(const char *, const char *, bool);
struct TorrentInfo torrent_get_info(int);
int torrent_count();
void torrent_pause(int);
void torrent_resume(int);
bool torrent_is_paused(int);
void torrent_remove(int);
void torrent_info_hash(int);
bool torrent_exists(const char *);
bool torrent_exists_from_magnet_uri(const char *);
void debug();
int torrent_next_index();
