//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef torrenter_bridging_header_h
#define torrenter_bridging_header_h

#include "torrents.h"

int torrent_initiate(const char *, const char *, bool);
int torrent_initiate_magnet_uri(const char *, const char *, bool);
void torrent_initiate_resume_data(const char *);
struct TorrentInfo torrent_get_info(int);
int torrent_count();
void torrent_pause(int);
void torrent_resume(int);
bool torrent_is_paused(int);
void torrent_remove(int);
int get_torrent_from_file(const char *);
int get_torrent_from_magnet_uri(const char *);
void debug(int);
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
void torrent_set_download_rate_limit(int, int);
void torrent_set_upload_rate_limit(int, int);
void torrent_fetch_peers(int);
struct PeerInfo *torrent_get_peer_info(int peer_index);
int torrent_peers_count();
struct Content torrent_get_content(int);
void torrent_content_destroy(struct Content);
struct ContentItemInfo torrent_item_info(int, int);
void torrent_item_info_destroy(struct ContentItemInfo);
void torrent_file_priority(int, int, int);
void torrent_fetch_files_progress(int);
void load_geo_ip_database(const char *);
void terminate();
const char *peer_get_country(const char *);
struct Trackers torrent_get_trackers(int);
struct TrackerInfo torrent_tracker_info(int);
const char *torrent_get_first_root_content_item_path(int);
struct Availability torrent_get_availability(int);
void add_extra_trackers_from_magnet_uri(const char *, int);
void add_extra_trackers_from_file(const char *, int);
void configure_libtorrent();

#endif
