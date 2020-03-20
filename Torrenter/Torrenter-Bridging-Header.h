//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "wrapper.h"

int torrent_initiate(const char *, const char *, bool);
int torrent_initiate_magnet_uri(const char *, const char *, bool);
void torrent_initiate_resume_data(const char *);
struct TorrentInfo torrent_get_info(int);
int torrent_count();
void torrent_pause(int);
void torrent_resume(int);
bool torrent_is_paused(int);
void torrent_remove(int);
bool torrent_exists(const char *);
bool torrent_exists_from_magnet_uri(const char *);
void debug();
int torrent_next_index();
struct TorrentPieces torrent_pieces(int);
void set_app_data_dir(const char *);
void spawn_alert_monitor();
void save_resume_data(int);
void save_all_resume_data();
void pause_session();
bool torrent_is_sequential(int);
void torrent_sequential(int, bool);
void torrent_force_recheck(int);
void torrent_force_reannounce(int);
void torrent_set_upload_rate_limit(int, int);
