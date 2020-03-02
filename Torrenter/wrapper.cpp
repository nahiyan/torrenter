//
//  wrapper.cpp
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/18/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

#include <iostream>
#include <vector>
#include <string>
#include "wrapper.h"

#include "libtorrent/entry.hpp"
#include "libtorrent/bencode.hpp"
#include "libtorrent/session.hpp"
#include "libtorrent/torrent_info.hpp"
#include "libtorrent/torrent_status.hpp"

std::vector<lt::torrent_handle> torrent_handlers;
std::vector<lt::session*> torrent_sessions;
std::vector<std::string*> torrent_names;

lt::session* torrent_session = new lt::session;

// Load torrent from file and start it
extern "C" void torrent_initiate(const char* loadPath, const char* savePath) {
    // Torrent params
    lt::add_torrent_params p;
    p.save_path = std::string(savePath);
    p.ti = std::make_shared<lt::torrent_info>(std::string(loadPath));

    // Torrent handler
    lt::torrent_handle th = torrent_session->add_torrent(p);
    torrent_handlers.push_back(th);
    
    // Register the name of the torrent
    std::string* name = new std::string(th.status().name);
    torrent_names.push_back(name);
}

// Get torrent struct representing the torrent itself
extern "C" TorrentInfo torrent_get_info(int index) {
    try {
        lt::torrent_handle th = torrent_handlers.at(index);
        lt::torrent_status ts = th.status();
        
        std::string* name;
        try {
            // if torrent name already exists, update it
            name = torrent_names.at(index);
        } catch(const std::out_of_range& oor) {
            // else register a new space and set it
            name = new std::string(ts.name);
            torrent_names.push_back(name);
        }
        
        TorrentInfo torrent_info;
        torrent_info.name = name->c_str();
        torrent_info.is_seeding = ts.is_seeding;
        torrent_info.is_finished = ts.is_finished;
        torrent_info.progress = ts.progress;
        torrent_info.num_seeds = ts.num_seeds;
        torrent_info.num_peers = ts.num_peers;
        torrent_info.list_seeds = ts.list_seeds;
        torrent_info.list_peers = ts.list_peers;
        torrent_info.download_rate = ts.download_rate;
        torrent_info.upload_rate = ts.upload_rate;
        torrent_info.status = (enum state_t) ts.state;
        
        return torrent_info;
    } catch(std::out_of_range) {
        TorrentInfo torrent_info;
        return torrent_info;
    }
}

// Number of torrents loaded in memory
extern "C" int torrent_count() {
    return (int) torrent_names.size();
}
