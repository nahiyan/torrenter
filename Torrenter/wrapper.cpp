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

// Load torrent from file and start it
extern "C" void torrent_initiate(const char* filePath, const char* savePath) {
    // Start session
    lt::session* s = new lt::session;
    torrent_sessions.push_back(s);
    
    // torrent params
    lt::add_torrent_params p;
    p.save_path = std::string(savePath);
    p.ti = std::make_shared<lt::torrent_info>(std::string(filePath));

    // Torrent handler
    lt::torrent_handle th = s->add_torrent(p);
    torrent_handlers.push_back(th);
    
    std::cout << "Torrent started..." << std::endl;
    
    std::string* name = new std::string(th.status().name);
    torrent_names.push_back(name);
}

// Get torrent struct representing the torrent itself
extern "C" Torrent torrent_get(int index) {
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
    
    Torrent torrent;
    torrent.name = name->c_str();
    torrent.is_seeding = ts.is_seeding;
    torrent.is_finished = ts.is_finished;
    torrent.progress = ts.progress;
    torrent.num_seeds = ts.num_seeds;
    torrent.num_peers = ts.num_peers;
    torrent.list_seeds = ts.list_seeds;
    torrent.list_peers = ts.list_peers;
    torrent.download_rate = ts.download_rate;
    torrent.upload_rate = ts.upload_rate;
    
    return torrent;
}

// Number of torrents loaded in memory
extern "C" int torrent_count() {
    return (int) torrent_names.size();
}
