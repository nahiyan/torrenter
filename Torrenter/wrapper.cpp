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
#include <unordered_map>
#include <utility>

#include "torrent.h"
#include "wrapper.h"
#include "libtorrent/entry.hpp"
#include "libtorrent/bencode.hpp"
#include "libtorrent/session.hpp"
#include "libtorrent/torrent_info.hpp"
#include "libtorrent/torrent_status.hpp"
#include "libtorrent/magnet_uri.hpp"

// Global variables
lt::session torrent_session = lt::session();
std::unordered_map<int, Torrent> torrents;

// Number of torrents loaded in memory
extern "C" int torrent_count()
{
    return (int)torrents.size();
}

// Load torrent from file and start it
extern "C" void torrent_initiate(const char *loadPath, const char *savePath, bool paused)
{
    // Torrent params
    lt::add_torrent_params params;
    params.save_path = std::string(savePath);
    params.ti = std::make_shared<lt::torrent_info>(std::string(loadPath));

    if (paused)
        params.flags = lt::torrent_flags::paused;

    Torrent torrent;
    torrent.handler = torrent_session.add_torrent(params);
    torrent.name = torrent.handler.status().name;

    torrents.insert(std::pair<int, Torrent>(torrent_count(), torrent));
}

// Load torrent from Magnet URI
extern "C" void torrent_initiate_magnet_uri(const char *magnetUri, const char *savePath, bool paused)
{
    // Torrent params
    lt::add_torrent_params params;
    params = libtorrent::parse_magnet_uri(magnetUri);
    params.save_path = std::string(savePath);

    if (paused)
        params.flags = lt::torrent_flags::paused;

    Torrent torrent;
    torrent.handler = torrent_session.add_torrent(params);
    torrent.name = torrent.handler.status().name;

    torrents.insert(std::pair<int, Torrent>(torrent_count(), torrent));

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
extern "C" TorrentInfo torrent_get_info(int index)
{
    try
    {
        lt::torrent_status status = torrents.at(index).handler.status();

        // Update the name of the torrent
        torrents.at(index).name = status.name;

        TorrentInfo torrent_info;
        torrent_info.name = torrents.at(index).name.c_str();
        torrent_info.is_seeding = status.is_seeding;
        torrent_info.is_finished = status.is_finished;
        torrent_info.progress = status.progress;
        torrent_info.num_seeds = status.num_seeds;
        torrent_info.num_peers = status.num_peers;
        torrent_info.list_seeds = status.list_seeds;
        torrent_info.list_peers = status.list_peers;
        torrent_info.download_rate = status.download_rate;
        torrent_info.upload_rate = status.upload_rate;
        torrent_info.status = (enum state_t)status.state;

        return torrent_info;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch torrent info." << std::endl;

        TorrentInfo torrent_info;
        return torrent_info;
    }
}

extern "C" void torrent_pause(int index)
{
    try
    {
        torrents.at(index).handler.unset_flags(lt::torrent_flags::auto_managed);
        torrents.at(index).handler.pause();
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to pause torrent." << std::endl;
    }
}

extern "C" void torrent_resume(int index)
{
    try
    {
        torrents.at(index).handler.set_flags(lt::torrent_flags::auto_managed, lt::torrent_flags::auto_managed);
        torrents.at(index).handler.resume();
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to resume torrent." << std::endl;
    }
}

extern "C" bool torrent_is_paused(int index)
{
    int flags;

    try
    {
        flags = (int)torrents.at(index).handler.flags();

        if (flags >= 32 && flags < 64)
        {
            return false;
        }
        else if (flags >= 16 && flags < 32)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch flags to determine if a torrent is paused or not." << index << std::endl;

        return false;
    }
}

extern "C" void torrent_remove(int index)
{
    try
    {
        lt::torrent_handle &handle = torrents.at(index).handler;
        torrent_session.remove_torrent(handle);
        torrents.erase(index);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to remove torrent" << std::endl;
    }
}
