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
#include <chrono>
#include <thread>
#include <memory>

#include "torrent.h"
#include "wrapper.h"
#include "libtorrent/entry.hpp"
#include "libtorrent/bencode.hpp"
#include "libtorrent/session.hpp"
#include "libtorrent/torrent_info.hpp"
#include "libtorrent/torrent_status.hpp"
#include "libtorrent/magnet_uri.hpp"
#include "libtorrent/sha1_hash.hpp"
#include "libtorrent/bitfield.hpp"
#include "libtorrent/alert.hpp"
#include "libtorrent/alert_types.hpp"
#include "libtorrent/write_resume_data.hpp"
#include "libtorrent/read_resume_data.hpp"

// Global variables
lt::session torrent_session = lt::session();
std::unordered_map<int, Torrent> torrents;
int next_index = 0;
std::shared_ptr<std::thread> alert_monitor;
std::string app_data_dir;

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

    Torrent torrent;
    torrent.handler = torrent_session.add_torrent(params);
    torrent.name = torrent.handler.status().name;

    // Handle flags
    if (paused)
        torrent.handler.set_flags(lt::torrent_flags::paused, lt::torrent_flags::paused);

    torrent.handler.set_flags(lt::torrent_flags::sequential_download, lt::torrent_flags::sequential_download);

    // Insert torrent in the index-mapped list
    torrents.insert(std::pair<int, Torrent>(next_index, torrent));

    next_index++;
}

// Load torrent from Magnet URI
extern "C" void torrent_initiate_magnet_uri(const char *magnetUri, const char *savePath, bool paused)
{
    // Torrent params
    lt::add_torrent_params params;
    params = lt::parse_magnet_uri(magnetUri);
    params.save_path = std::string(savePath);

    Torrent torrent;
    torrent.handler = torrent_session.add_torrent(params);
    torrent.name = torrent.handler.status().name;

    // Handle flags
    if (paused)
        torrent.handler.set_flags(lt::torrent_flags::paused, lt::torrent_flags::paused);

    torrent.handler.set_flags(lt::torrent_flags::sequential_download, lt::torrent_flags::sequential_download);

    // Insert torrent in the index-mapped list
    torrents.insert(std::pair<int, Torrent>(next_index, torrent));

    next_index++;
}

// Load torrent from resume data
extern "C" void torrent_initiate_resume_data(const char *file_name)
{
    // Read resume data
    std::ifstream ifs(app_data_dir + "/resume_files/" + file_name, std::ios_base::binary);
    ifs.unsetf(std::ios_base::skipws);
    std::vector<char> buf{std::istream_iterator<char>(ifs), std::istream_iterator<char>()};

    // Torrent params
    lt::add_torrent_params params;
    params = lt::read_resume_data(buf);

    Torrent torrent;
    torrent.handler = torrent_session.add_torrent(params);
    torrent.name = torrent.handler.status().name;

    // torrent.handler.set_flags(lt::torrent_flags::sequential_download, lt::torrent_flags::sequential_download);

    // Insert torrent in the index-mapped list
    torrents.insert(std::pair<int, Torrent>(next_index, torrent));

    next_index++;
}

extern "C" void pause_session()
{
    torrent_session.pause();
}

// Get torrent struct representing the torrent itself
extern "C" TorrentInfo torrent_get_info(int index)
{
    try
    {
        lt::torrent_status status = torrents.at(index).handler.status();
        lt::torrent_handle handler = torrents.at(index).handler;

        // Update the name of the torrent
        torrents.at(index).name = status.name;

        // Update the save path of the torrent
        torrents.at(index).save_path = status.save_path;

        TorrentInfo torrent_info;
        torrent_info.name = torrents.at(index).name.c_str();
        torrent_info.is_seeding = status.is_seeding;
        torrent_info.is_finished = status.is_finished;
        torrent_info.progress = status.progress;
        torrent_info.num_seeds = status.num_seeds;
        torrent_info.num_peers = status.num_peers;
        torrent_info.list_seeds = status.list_seeds;
        torrent_info.list_peers = status.list_peers;
        torrent_info.size = status.total;
        torrent_info.downloaded = status.total_done;
        torrent_info.uploaded = status.all_time_upload;
        torrent_info.next_announce = (int)std::chrono::duration_cast<std::chrono::seconds>(status.next_announce).count();
        torrent_info.wasted = status.total_failed_bytes;
        torrent_info.connections = status.num_connections;
        torrent_info.download_limit = handler.download_limit();
        torrent_info.upload_limit = handler.upload_limit();
        torrent_info.download_rate = status.download_rate;
        torrent_info.upload_rate = status.upload_rate;
        torrent_info.status = (enum state_t)status.state;
        torrent_info.active_duration = (int)status.active_duration.count();
        torrent_info.total_wanted = (float)status.total_wanted;
        torrent_info.total_wanted_done = (float)status.total_wanted_done;
        torrent_info.save_path = torrents.at(index).save_path.c_str();

        return torrent_info;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch torrent info." << index << std::endl;

        TorrentInfo torrent_info;
        return torrent_info;
    }
}

extern "C" void torrent_pause(int index)
{
    try
    {
        torrents.at(index).handler.unset_flags(lt::torrent_flags::stop_when_ready);
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
        torrents.at(index).handler.unset_flags(lt::torrent_flags::stop_when_ready);
        torrents.at(index).handler.set_flags(lt::torrent_flags::auto_managed, lt::torrent_flags::auto_managed);
        torrents.at(index).handler.resume();
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to resume torrent." << std::endl;
    }
}

extern "C" void torrent_force_recheck(int index)
{
    try
    {
        torrents.at(index).handler.force_recheck();
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to force recheck torrent." << std::endl;
    }
}

extern "C" void torrent_force_reannounce(int index)
{
    try
    {
        torrents.at(index).handler.force_reannounce(0);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to force reannounce torrent." << std::endl;
    }
}

extern "C" bool torrent_is_paused(int index)
{
    int64_t flags;
    int64_t mask = 0x0000000000000010;

    try
    {
        flags = (int)torrents.at(index).handler.flags();

        if ((flags & mask) == mask)
            return true;
        else
            return false;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch flags to determine if a torrent is paused or not." << std::endl;

        return false;
    }
}

extern "C" bool torrent_is_sequential(int index)
{
    int64_t flags;
    int64_t mask = 0x0000000000000200;

    try
    {
        flags = (int)torrents.at(index).handler.flags();

        if ((flags & mask) == mask)
            return true;
        else
            return false;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch flags to determine if a torrent is sequential or not." << std::endl;

        return false;
    }
}

extern "C" void torrent_sequential(int index, bool sequential)
{
    try
    {
        lt::torrent_handle &handler = torrents.at(index).handler;

        if (sequential)
        {
            handler.set_flags(lt::torrent_flags::sequential_download, lt::torrent_flags::sequential_download);
        }
        else
        {
            handler.unset_flags(lt::torrent_flags::sequential_download);
        }
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to set/unset torrent to sequential." << std::endl;
    }
}

extern "C" void torrent_remove(int index)
{
    try
    {
        lt::torrent_handle &handler = torrents.at(index).handler;
        torrent_session.remove_torrent(handler);
        torrents.erase(index);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to remove torrent" << std::endl;
    }
}

extern "C" bool torrent_exists(const char *loadPath)
{
    lt::torrent_info info = lt::torrent_info(std::string(loadPath));
    lt::sha1_hash hash = info.info_hash();

    bool exists = false;
    for (auto it = torrents.begin(); it != torrents.end(); ++it)
    {
        if (it->second.handler.info_hash() == hash)
        {
            exists = true;
            break;
        }
    }

    return exists;
}

extern "C" bool torrent_exists_from_magnet_uri(const char *magnet_uri)
{
    lt::add_torrent_params params = lt::parse_magnet_uri(magnet_uri);
    lt::sha1_hash hash = params.info_hash;

    bool exists = false;
    for (auto it = torrents.begin(); it != torrents.end(); ++it)
    {
        if (it->second.handler.info_hash() == hash)
        {
            exists = true;
            break;
        }
    }

    return exists;
}

extern "C" int torrent_next_index()
{
    return next_index;
}

extern "C" TorrentPieces torrent_pieces(int index)
{
    try
    {
        // torrent
        Torrent torrent = torrents.at(index);

        // pieces
        lt::typed_bitfield<lt::piece_index_t> pieces = torrent.handler.status().pieces;

        // Get the download queue
        std::vector<lt::partial_piece_info> queue;
        torrent.handler.get_download_queue(queue);

        // update the piece info of the torrent
        torrent.pieces.count = pieces.size();
        // delete[] torrent.pieces.content;
        torrent.pieces.content = new piece_state_t[torrent.pieces.count];

        // construct the array
        for (int i = 0; i < torrent.pieces.count; i++)
        {
            if (pieces[i])
                torrent.pieces.content[i] = piece_finished;
            else
                torrent.pieces.content[i] = piece_unknown;
        }

        for (auto it = queue.begin(); it != queue.end(); it++)
        {
            torrent.pieces.content[it->piece_index] = piece_downloading;
        }

        return torrent.pieces;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch torrent pieces" << std::endl;
    }

    return TorrentPieces();
}

extern "C" void debug()
{
    if (torrent_count() >= 1)
    {

        try
        {
            lt::torrent_handle handler = torrents.at(0).handler;

            // Get the download queue
            std::vector<lt::partial_piece_info> queue;
            handler.get_download_queue(queue);

            // See what's in the queue
            for (auto it = queue.begin(); it != queue.end(); ++it)
            {
                std::cout << it->piece_index << std::endl;
            }
        }
        catch (std::out_of_range)
        {
            std::cout << "Debug error" << std::endl;
        }
    }
}

extern "C" void save_resume_data(int index)
{
    try
    {
        Torrent torrent = torrents.at(index);
        if (torrent.handler.need_save_resume_data())
        {
            torrent.handler.save_resume_data(lt::torrent_handle::flush_disk_cache | lt::torrent_handle::save_info_dict | lt::torrent_handle::only_if_modified);
        }
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to save resume data." << std::endl;
    }
}

extern "C" void save_all_resume_data()
{
    for (std::pair<int, Torrent> torrent : torrents)
    {
        save_resume_data(torrent.first);
    }
}

extern "C" void set_app_data_dir(const char *dir)
{
    app_data_dir = std::string(dir);
}

void monitor_alerts()
{
    while (true)
    {
        // retrieve the alerts
        std::vector<lt::alert *> alerts;
        torrent_session.pop_alerts(&alerts);

        for (lt::alert *alert : alerts)
        {
            switch (alert->type())
            {
            case lt::save_resume_data_alert::alert_type:
            {
                lt::save_resume_data_alert const *srd_alert = lt::alert_cast<lt::save_resume_data_alert>(alert);

                std::string name = srd_alert->handle.status(lt::torrent_handle::query_name).name;

                std::string resume_file = app_data_dir + "/resume_files/" + name + ".resume";

                std::ofstream out(resume_file, std::ios_base::binary);
                std::vector<char> buf = lt::write_resume_data_buf(srd_alert->params);
                out.write(buf.data(), buf.size());

                break;
            }
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }
}

extern "C" void spawn_alert_monitor()
{
    alert_monitor = std::make_shared<std::thread>(monitor_alerts);
}

extern "C" void torrent_set_upload_rate_limit(int index, int upload_rate_limit)
{
    try
    {
        Torrent torrent = torrents.at(index);
        torrent.handler.set_upload_limit(upload_rate_limit);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to set upload rate limit." << std::endl;
    }
}
