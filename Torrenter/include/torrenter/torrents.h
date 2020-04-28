//
//  torrents.h
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/21/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

#ifndef torrents_h
#define torrents_h

#include <stdbool.h>
#include <stdint.h>

enum state_t
{
    checking_files,
    downloading_metadata,
    downloading,
    finished,
    seeding,
    allocating,
    checking_resume_data,
};

enum piece_state_t
{
    piece_unknown,
    piece_downloading,
    piece_finished,
};

struct TorrentPieces
{
    enum piece_state_t *content;
    int count;
};

struct Availability
{
    enum piece_state_t *content;
    int count;
    float value;
};

struct TorrentInfo
{
    const char *name;
    float progress;
    bool is_finished;
    bool is_seeding;
    int num_seeds;
    int num_peers;
    int num_pieces;
    int num_pieces_total;
    const char *comment;
    const char *creator;
    int piece_size;
    int list_seeds;
    int list_peers;
    float size;
    float downloaded;
    float uploaded;
    int next_announce;
    float wasted;
    int connections;
    int download_limit;
    int upload_limit;
    int download_rate;
    int upload_rate;
    enum state_t status;
    int active_duration;
    float total_wanted;
    float total_wanted_done;
    const char *save_path;
    const char *info_hash;
    double added_on;
    double completed_on;
    double created_on;
};

struct PeerInfo
{
    const char *ip_address;
    unsigned long _ip_address;
    const char *client;
    int up_rate;
    int down_rate;
    int64_t total_down;
    int64_t total_up;
    float progress;
    int connection_type;
    unsigned short port;
};

struct ContentItem
{
    const char *name;
    int parent;
    int id;
    int level;
    bool isDirectory;
    int file_index;
};

struct Content
{
    struct ContentItem **items;
    int count;
};

struct TrackerInfo
{
    const char *url;
    unsigned char tier;
    bool is_working;
    bool is_updating;
    const char *message;
    int seeds;
    int peers;
    int downloaded;
};

struct Trackers
{
    struct TrackerInfo **items;
    int count;
};

struct ContentItemInfo
{
    int priority;
    float size;
    float progress;
    const char *path;
    const char *parent_path;
};

#endif /* torrent_h */
