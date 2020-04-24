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
#include <cstdlib>
#include <cstring>
#include <fstream>

#include "../../include/torrenter/torrent.h"
#include "../../include/torrenter/torrents.h"
extern "C"
{
#include "maxminddb.h"
#include "../../include/torrenter/geo_ip.h"
}
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
int next_index = 0;
std::unordered_map<int, Torrent> torrents;
std::shared_ptr<std::thread> alert_monitor;
std::string app_data_dir;
std::vector<lt::peer_info> peers;
std::vector<PeerInfo> peer_infos;
struct Trackers trackers;
MMDB_s mmdb;

const char *c_string(std::string str)
{
    char *c_str = new char[str.size() + 1];
    sprintf(c_str, "%s", str.c_str());

    return (const char *)c_str;
}

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
    try
    {
        params = lt::read_resume_data(buf);

        Torrent torrent;
        torrent.handler = torrent_session.add_torrent(params);
        torrent.name = torrent.handler.status().name;

        // Insert torrent in the index-mapped list
        torrents.insert(std::pair<int, Torrent>(next_index, torrent));

        next_index++;
    }
    catch (...)
    {
        std::cout << "Failed to read resume data for " + std::string(file_name) + "\n";
        std::cout << "Removing the resume file\n";
        std::string _filepath = app_data_dir + "/resume_files/" + file_name;
        const char *filepath = c_string(_filepath);
        if (std::remove(filepath) == 0)
        {
            std::cout << "Successfully removed resume file.\n";
        }
        else
        {
            std::cout << "Failed to remove resume file.\n";
        }
        free((char *)filepath);
    }
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
        const lt::torrent_info *info = handler.torrent_file().get();

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

        if (info != NULL)
        {
            torrent_info.comment = info->comment().c_str();
            torrent_info.creator = info->creator().c_str();
            torrent_info.piece_size = info->piece_length();
            torrent_info.num_pieces_total = info->num_pieces();
        }
        else
        {
            torrent_info.comment = "";
            torrent_info.creator = "";
            torrent_info.piece_size = 0;
            torrent_info.num_pieces_total = 0;
        }

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

        // Destroy previously created peer infos
        for (PeerInfo peer_info : peer_infos)
        {
            delete[] peer_info.ip_address;
        }

        peer_infos.clear();

        for (auto it = peers.begin(); it != peers.end(); it++)
        {
            PeerInfo peer_info = PeerInfo();

            std::stringstream address_ss;
            address_ss << it->ip.address();
            peer_info.ip_address = c_string(address_ss.str());
            peer_info.client = it->client.c_str();
            peer_info.port = it->ip.port();
            peer_info.up_rate = it->up_speed;
            peer_info.down_rate = it->down_speed;
            peer_info.progress = it->progress;
            peer_info.connection_type = it->connection_type;
            peer_info.total_down = it->total_download;
            peer_info.total_up = it->total_upload;
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
        return peer_infos.at(peer_index);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch peer info." << std::endl;

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

extern "C" void debug(int selection)
{
    if (torrent_count() >= 1)
    {
        try
        {
            const lt::torrent_info *info = torrents.at(selection).handler.torrent_file().get();

            lt::file_storage files = info->files();

            int num_files = files.num_files();
            std::cout << "Number of files: " << num_files << std::endl;

            std::cout << "Files: " << std::endl;
            for (int i = 0; i < num_files; i++)
            {
                std::cout << i << ". " << files.file_path(i) << " -> " << files.file_name(i) << std::endl;
            }

            std::cout << "Paths: " << std::endl;

            std::vector<std::string> paths = files.paths();

            for (auto it = paths.begin(); it != paths.end(); it++)
            {
                std::cout << "Path: " << *it << std::endl;
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

const std::vector<std::string> explode(const std::string &s, const char &c)
{
    std::string buff{""};
    std::vector<std::string> v;

    for (auto n : s)
    {
        if (n != c)
            buff += n;
        else if (n == c && buff != "")
        {
            v.push_back(buff);
            buff = "";
        }
    }
    if (buff != "")
        v.push_back(buff);

    return v;
}

const std::string implode(std::vector<std::string> &segments, const char &c)
{
    std::string value;
    for (std::string segment : segments)
    {
        value += segment + c;
    }

    return value;
}

extern "C" void torrent_content_destroy(Content content)
{
    for (int i = 0; i < content.count; i++)
    {
        ContentItem *item = content.items[i];
        delete[] item->name;
        free(content.items[i]);
    }

    free(content.items);
}

int content_item_find(std::string name, int level, ContentItem **content_items, int content_items_count)
{
    for (int i = 0; i < content_items_count; i++)
    {
        if (strcmp(name.c_str(), content_items[i]->name) == 0 && content_items[i]->level == level)
        {
            return i;
        }
    }

    return -1;
}

extern "C" Content torrent_get_content(int index)
{
    try
    {
        const lt::torrent_info *info = torrents.at(index).handler.torrent_file().get();

        lt::file_storage files = info->files();
        ContentItem **content_items = (ContentItem **)malloc(0);
        int id = 0;

        // Go through all the files
        for (auto i : files.file_range())
        {
            std::vector<std::string> segments = explode(files.file_path(i), '/');

            if (segments.size() > 0)
            {
                // Take the file name and remove it from segments
                std::string file_name = segments[segments.size() - 1];
                segments.pop_back();

                // Process all the segments
                int level = 0;
                for (auto it = segments.begin(); it != segments.end(); it++)
                {
                    if (content_item_find(*it, level, content_items, id) == -1)
                    {
                        ContentItem *item = new ContentItem();

                        // name
                        item->name = c_string(*it);

                        // parent
                        if (it == segments.begin())
                        {
                            item->parent = -1;
                        }
                        else
                        {
                            item->parent = id - 1;
                        }

                        // id
                        item->id = id;
                        id++;

                        // level
                        item->level = level;

                        // is directory
                        item->isDirectory = true;

                        // file index
                        item->file_index = -1;

                        // insert it in the list
                        content_items = (ContentItem **)realloc(content_items, sizeof(ContentItem *) * id);
                        content_items[id - 1] = item;
                    }
                    level++;
                }

                // Process the file segment
                ContentItem *item = new ContentItem();

                // name
                item->name = c_string(file_name);

                // parent
                if (segments.size() == 0)
                {
                    item->parent = -1;
                }
                else
                {
                    item->parent = content_item_find(segments[segments.size() - 1], (int)segments.size() - 1, content_items, id);
                }

                // id
                item->id = id;
                id++;

                // level
                item->level = (int)segments.size();

                // is directory
                item->isDirectory = false;

                // file index
                item->file_index = i;

                // insertion
                content_items = (ContentItem **)realloc(content_items, sizeof(ContentItem *) * id);
                content_items[id - 1] = item;
            }
        }

        Content content;
        content.items = content_items;
        content.count = id;

        return content;
    }
    catch (std::out_of_range)
    {
        std::cout << "Error trying to get content of torrent" << std::endl;
    }

    Content content;
    return content;
}

extern "C" ContentItemInfo torrent_item_info(int index, int item_index)
{
    try
    {
        Torrent torrent = torrents.at(index);

        ContentItemInfo info;
        info.priority = (int)torrent.handler.file_priority(item_index);
        info.size = (float)torrent.handler.torrent_file()->files().file_size(item_index);
        try
        {
            info.progress = (float)torrent.files_progress.at(item_index);
        }
        catch (std::out_of_range)
        {
            info.progress = 0;
        }

        std::string save_path = torrent.save_path;
        info.path = c_string(torrent.handler.torrent_file()->files().file_path(item_index, save_path));

        std::vector<std::string> segments = explode(info.path, '/');
        if (segments.size() == 1)
        {
            info.parent_path = "/";
        }
        else
        {
            segments.pop_back();
            info.parent_path = c_string("/" + implode(segments, '/'));
        }

        return info;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to get torrent content item info." << std::endl;
    }

    return ContentItemInfo();
}

extern "C" const char *torrent_get_first_root_content_item_path(int index)
{
    Content content = torrent_get_content(index);
    if (content.count > 0)
    {
        ContentItem *content_item = content.items[0];

        const char *_path = torrent_item_info(index, content_item->id).path;
        char *path = (char *)calloc(strlen(_path), sizeof(char));
        strcpy(path, _path);

        torrent_content_destroy(content);

        return (const char *)path;
    }
    else
    {
        torrent_content_destroy(content);
        return nullptr;
    }
}

extern "C" void torrent_item_info_destroy(ContentItemInfo info)
{
    delete[] info.path;
    delete[] info.parent_path;
}

extern "C" void torrent_fetch_files_progress(int index)
{
    try
    {
        torrents.at(index).handler.file_progress(torrents.at(index).files_progress);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to fetch torrent files' progress" << std::endl;
    }
}

extern "C" void torrent_file_priority(int index, int item_index, int priority)
{
    try
    {
        Torrent torrent = torrents.at(index);

        torrent.handler.file_priority(item_index, priority);
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to set torrent content item priority." << std::endl;
    }
}

extern "C" void load_geo_ip_database(const char *location)
{
    open_db(location, &mmdb);
}

extern "C" void terminate()
{
    save_all_resume_data();
    close_db(&mmdb);
}

extern "C" const char *peer_get_country(const char *ip_address)
{
    const char *country;
    if (get_country(&mmdb, ip_address, &country))
    {
        return country;
    }
    else
    {
        return (const char *)malloc(0 * sizeof(char));
    }
}

extern "C" void torrent_trackers_destroy(Trackers trackers)
{
    for (int i = 0; i < trackers.count; i++)
    {
        free((char *)trackers.items[i]->url);
        free(trackers.items[i]);
    }
    free(trackers.items);
}

extern "C" Trackers torrent_get_trackers(int index)
{
    try
    {
        Torrent torrent = torrents.at(index);

        std::vector<lt::announce_entry> _trackers = torrent.handler.trackers();

        torrent_trackers_destroy(trackers);

        trackers.items = (TrackerInfo **)calloc(_trackers.size(), sizeof(TrackerInfo));
        trackers.count = (int)_trackers.size();

        int i = 0;
        for (lt::announce_entry _tracker : _trackers)
        {
            TrackerInfo *tracker = new TrackerInfo;
            tracker->url = c_string(_tracker.url);
            tracker->tier = (unsigned char)_tracker.tier;
            tracker->is_working = false;
            tracker->message = (const char *)malloc(0);
            tracker->is_updating = false;

            for (lt::announce_endpoint endpoint : _tracker.endpoints)
            {
                if (endpoint.is_working())
                {
                    tracker->is_working = true;
                }
                if (endpoint.updating)
                {
                    tracker->is_updating = true;
                }
                if (endpoint.message.size() >= 1)
                {
                    free((char *)tracker->message);
                    tracker->message = c_string(endpoint.message);
                }
            }

            trackers.items[i] = tracker;
            i++;
        }

        return trackers;
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to get trackers list." << std::endl;

        return trackers;
    }
}

extern "C" TrackerInfo torrent_tracker_info(int item_index)
{
    try
    {
        return *trackers.items[item_index];
    }
    catch (std::out_of_range)
    {
        std::cout << "Failed to get tracker." << std::endl;

        return TrackerInfo();
    }
}
