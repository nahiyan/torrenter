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
#include <cstdio>

#include "../../include/torrenter/torrent.h"
#include "../../include/torrenter/torrents.h"
#include "../../include/torrenter/peer_info.h"
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
std::vector<lt::peer_info> peers;
std::vector<PeerInfo_> peer_infos;

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

    // Insert torrent in the index-mapped list
    torrents.insert(std::pair<int, Torrent>(next_index, torrent));

    next_index++;
}

extern "C" void pause_session()
{
    torrent_session.pause();
}

char hex_encode_int(uint8_t value)
{
    if (value >= 0 && value <= 9)
        return value + 48;
    else if (value >= 10 && value <= 15)
        return value + 87;
    else
        return '0';
}

std::string hex_encode_sha1_hash(lt::sha1_hash hash)
{
    std::string encoded_hash;

    // Right-most-bit mask
    uint32_t rmb_mask = 0x00000001;

    // Each 4 bits of the byte is represented by a uint8_t
    uint8_t byte_integers[2];

    // SHA1 hash byte
    uint32_t hash_byte;

    // Loop through the bytes of the hash (20 in total), converting each byte to 2 hex chars
    for (auto it = hash.begin(); it != hash.end(); it++)
    {
        hash_byte = *it;

        for (int j = 1; j >= 0; j--)
        {
            byte_integers[j] = 0;

            for (int i = 0; i < 4; i++)
            {
                if (hash_byte & rmb_mask)
                    byte_integers[j] += pow(2, i);

                hash_byte = hash_byte >> 1;
            }
        }

        encoded_hash += hex_encode_int(byte_integers[0]);
        encoded_hash += hex_encode_int(byte_integers[1]);
    }

    return encoded_hash;
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

        // Update the info hash
        torrents.at(index).info_hash = hex_encode_sha1_hash(handler.info_hash());

        TorrentInfo torrent_info;
        torrent_info.name = torrents.at(index).name.c_str();
        torrent_info.is_seeding = status.is_seeding;
        torrent_info.is_finished = status.is_finished;
        torrent_info.progress = status.progress;
        torrent_info.num_seeds = status.num_seeds;
        torrent_info.num_peers = status.num_peers;
        torrent_info.num_pieces = status.num_pieces;
        torrent_info.comment = handler.torrent_file()->comment().c_str();
        torrent_info.creator = handler.torrent_file()->creator().c_str();
        torrent_info.piece_size = handler.torrent_file()->piece_length();
        torrent_info.num_pieces_total = handler.torrent_file()->num_pieces();
        torrent_info.list_seeds = status.list_seeds;
        torrent_info.list_peers = status.list_peers;
        torrent_info.size = status.total_wanted;
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
        torrent_info.info_hash = torrents.at(index).info_hash.c_str();

        return torrent_info;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch torrent info." << index << std::endl;

        TorrentInfo torrent_info;
        return torrent_info;
    }
}

// Fetch list of peers
extern "C" void torrent_fetch_peers(int index)
{
    try
    {
        lt::torrent_handle &handler = torrents.at(index).handler;

        handler.get_peer_info(peers);

        peer_infos.clear();

        for (auto it = peers.begin(); it != peers.end(); it++)
        {
            PeerInfo_ peer_info = PeerInfo_();
            peer_info.ip_address = it->ip.address().to_string();
            peer_infos.push_back(peer_info);
        }
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch torrent peers." << index << std::endl;
    }
}

extern "C" PeerInfo torrent_get_peer_info(int peer_index)
{
    try
    {
        PeerInfo_ &peer_info = peer_infos.at(peer_index);

        PeerInfo peer_info2 = PeerInfo();
        peer_info2.ip_address = peer_info.ip_address.c_str();

        return peer_info2;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch peer of torrent." << std::endl;

        return PeerInfo();
    }
}

extern "C" int torrent_peers_count()
{
    return (int)peers.size();
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

        // Remove torrent from session
        torrent_session.remove_torrent(handler);

        // Remove torrent from unordered map
        torrents.erase(index);

        // Remove resume data of torrent
        std::string encoded_hash = hex_encode_sha1_hash(handler.info_hash());

        std::string resume_file = app_data_dir + "/resume_files/" + encoded_hash + ".resume";

        std::ifstream infile(resume_file);
        if (infile.good())
        {
            if (std::remove(resume_file.c_str()) != 0)
            {
                std::cout << "Failed to remove resume file." << std::endl;
            }
        }
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

                try
                {
                    std::string encoded_hash = hex_encode_sha1_hash(srd_alert->handle.info_hash());

                    std::string resume_file = app_data_dir + "/resume_files/" + encoded_hash + ".resume";

                    // Write resume file
                    std::ofstream out(resume_file, std::ios_base::binary);
                    std::vector<char> buf = lt::write_resume_data_buf(srd_alert->params);
                    out.write(buf.data(), buf.size());
                }
                catch (...)
                {
                    std::cout << "Unknown exception caught." << std::endl;
                }

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

extern "C" void torrent_set_download_rate_limit(int index, int rate_limit)
{
    try
    {
        Torrent torrent = torrents.at(index);
        torrent.handler.set_download_limit(rate_limit);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to set download rate limit." << std::endl;
    }
}

extern "C" void torrent_set_upload_rate_limit(int index, int rate_limit)
{
    try
    {
        Torrent torrent = torrents.at(index);
        torrent.handler.set_upload_limit(rate_limit);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to set upload rate limit." << std::endl;
    }
}
