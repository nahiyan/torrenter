//
//  wrapper.h
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/21/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

#ifndef wrapper_h
#define wrapper_h

#include <stdbool.h>

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

struct TorrentInfo
{
    const char *name;
    float progress;
    bool is_finished;
    bool is_seeding;
    int num_seeds;
    int num_peers;
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
};

struct PeerInfo
{
    const char* ip_address;
};

#endif /* wrapper_h */
