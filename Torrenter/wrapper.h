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

struct TorrentInfo {
    const char* name;
    float progress;
    bool is_finished;
    bool is_seeding;
    int num_seeds;
    int num_peers;
    int list_seeds;
    int list_peers;
    int download_rate;
    int upload_rate;
};

#endif /* wrapper_h */
