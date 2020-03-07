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
#include "libtorrent/magnet_uri.hpp"

std::vector<lt::torrent_handle> torrent_handlers;
std::vector<lt::session*> torrent_sessions;
std::vector<std::string*> torrent_names;

lt::session* torrent_session = new lt::session;

// Load torrent from file and start it
extern "C" void torrent_initiate(const char* loadPath, const char* savePath, bool paused) {
    // Torrent params
    lt::add_torrent_params p;
    p.save_path = std::string(savePath);
    p.ti = std::make_shared<lt::torrent_info>(std::string(loadPath));
    
    if (paused)
        p.flags = lt::torrent_flags::paused;

    // Torrent handler
    lt::torrent_handle th = torrent_session->add_torrent(p);
    torrent_handlers.push_back(th);
    
    // Register the name of the torrent
    std::string* name = new std::string(th.status().name);
    torrent_names.push_back(name);
}

extern "C" void torrent_initiate_magnet_uri(const char* magnetUri, const char* savePath, bool paused) {
    // Torrent params
    lt::add_torrent_params p;
    p = libtorrent::parse_magnet_uri(magnetUri);
    p.save_path = std::string(savePath);
    
    if (paused)
        p.flags = lt::torrent_flags::paused;

    // Torrent handler
    lt::torrent_handle th = torrent_session->add_torrent(p);
    torrent_handlers.push_back(th);
    
    // Register the name of the torrent
    std::string* name = new std::string(th.status().name);
    torrent_names.push_back(name);
    
//    bool hmd = th.status().has_metadata;
//    while(!hmd) {
//        hmd = th.status().has_metadata;
//    }
//
//    if (hmd) {
//        std::shared_ptr<const lt::torrent_info> tf = th.torrent_file();
//        std::cout << tf->metadata_size() << std::endl;
//    } else {
//        std::cout << "No metadata" << std::endl;
//    }
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

extern "C" void torrent_flags(int index) {
    torrent_handlers.at(index).unset_flags(lt::torrent_flags::auto_managed);
//    torrent_handlers.at(index).set_flags(lt::torrent_flags::stop_when_ready, lt::torrent_flags::stop_when_ready);
    
    torrent_handlers.at(index).resume();
    
    std::cout << torrent_handlers.at(index).flags() << std::endl;
}

extern "C" void torrent_pause(int index) {
    torrent_handlers.at(index).unset_flags(lt::torrent_flags::auto_managed);
    torrent_handlers.at(index).pause();
}

extern "C" void torrent_resume(int index) {
    torrent_handlers.at(index).set_flags(lt::torrent_flags::auto_managed, lt::torrent_flags::auto_managed);
    torrent_handlers.at(index).resume();
}

extern "C" bool torrent_is_paused(int index) {
    int flags = (int) torrent_handlers.at(index).flags();
    
    if (flags >= 32 && flags < 64) {
        return false;
    } else if (flags >= 16 && flags < 32) {
        return true;
    } else {
        return false;
    }
}
