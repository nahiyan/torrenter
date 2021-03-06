//
//  wrapper.cpp
//  Torrenter
//
//  Created by Nahiyan Alamgir on 2/18/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

#include <boost/asio.hpp>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

#include "torrenter/names_database.h"
#include "torrenter/torrent.h"
#include "torrenter/torrents.h"
extern "C" {
#include "libmaxminddb/maxminddb.h"
#include "torrenter/geo_ip.h"
}
#include "libtorrent/alert.hpp"
#include "libtorrent/alert_types.hpp"
#include "libtorrent/bencode.hpp"
#include "libtorrent/bitfield.hpp"
#include "libtorrent/entry.hpp"
#include "libtorrent/magnet_uri.hpp"
#include "libtorrent/read_resume_data.hpp"
#include "libtorrent/session.hpp"
#include "libtorrent/sha1_hash.hpp"
#include "libtorrent/torrent_info.hpp"
#include "libtorrent/torrent_status.hpp"
#include "libtorrent/write_resume_data.hpp"

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
bool stop_alert_monitor = false;

const char* get_app_data_dir()
{
    return app_data_dir.c_str();
}

const char* c_string(std::string str)
{
    char* c_str = new char[str.size() + 1];
    sprintf(c_str, "%s", str.c_str());

    return (const char*)c_str;
}

// Number of torrents loaded in memory
extern "C" int torrent_count()
{
    return (int)torrents.size();
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
    for (auto it = hash.begin(); it != hash.end(); it++) {
        hash_byte = *it;

        for (int j = 1; j >= 0; j--) {
            byte_integers[j] = 0;

            for (int i = 0; i < 4; i++) {
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

void write_torrent_resume_file(lt::torrent_handle const& handle, lt::add_torrent_params const& params)
{
    try {
        std::string encoded_hash = hex_encode_sha1_hash(handle.info_hash());

        std::string resume_file = app_data_dir + "/resume_files/" + encoded_hash + ".resume";

        // Save name in a database for those torrents whose metadata isn't yet downloaded
        if (params.ti == NULL) {
            std::string name = params.name;

            load_names_if_required();
            add_name(encoded_hash, name);
            save_names();
        }

        // Write resume file
        std::ofstream out(resume_file, std::ios_base::binary);
        std::vector<char> buf = lt::write_resume_data_buf(params);
        out.write(buf.data(), buf.size());
    } catch (...) {
        std::cout << "Error occurred whilst saving resume data." << std::endl;
    }
}

// Load torrent from file and start it
extern "C" void torrent_initiate(const char* loadPath, const char* savePath, bool paused)
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

    // Default pieces information
    TorrentPieces pieces;
    pieces.content = (piece_state_t*)malloc(0);
    pieces.count = 0;

    torrent.pieces = pieces;

    // Save resume file
    write_torrent_resume_file(torrent.handler, params);

    // Insert torrent in the index-mapped list
    torrents.insert(std::pair<int, Torrent>(next_index, torrent));

    next_index++;
}

// Load torrent from Magnet URI
extern "C" void torrent_initiate_magnet_uri(const char* magnetUri, const char* savePath, bool paused)
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

    // Default pieces information
    TorrentPieces pieces;
    pieces.content = (piece_state_t*)malloc(0);
    pieces.count = 0;

    torrent.pieces = pieces;

    // Save resume file
    write_torrent_resume_file(torrent.handler, params);

    // Insert torrent in the index-mapped list
    torrents.insert(std::pair<int, Torrent>(next_index, torrent));

    next_index++;
}

// Load torrent from resume data
extern "C" void torrent_initiate_resume_data(const char* file_name)
{
    // Read resume data
    std::ifstream ifs(app_data_dir + "/resume_files/" + file_name, std::ios_base::binary);
    ifs.unsetf(std::ios_base::skipws);
    std::vector<char> buf { std::istream_iterator<char>(ifs), std::istream_iterator<char>() };

    // Torrent params
    try {
        lt::add_torrent_params params = lt::read_resume_data(buf);

        Torrent torrent;
        torrent.handler = torrent_session.add_torrent(params);

        if (params.ti == NULL) {
            // Get name from database if metadata isn't still downloaded
            std::stringstream ss;
            ss << params.info_hashes.get_best();
            std::string hash = ss.str();
            load_names_if_required();
            torrent.name = get_name(hash);
        } else {
            torrent.name = params.ti->name();
        }

        // Default pieces information
        TorrentPieces pieces;
        pieces.content = (piece_state_t*)malloc(0);
        pieces.count = 0;

        torrent.pieces = pieces;

        // Insert torrent in the index-mapped list
        torrents.insert(std::pair<int, Torrent>(next_index, torrent));

        next_index++;
    } catch (...) {
        std::cout << "Failed to read resume data for " + std::string(file_name) + "\n";
        std::cout << "Removing the resume file\n";
        std::string _filepath = app_data_dir + "/resume_files/" + file_name;
        const char* filepath = c_string(_filepath);
        if (std::remove(filepath) == 0) {
            std::cout << "Successfully removed resume file.\n";
        } else {
            std::cout << "Failed to remove resume file.\n";
        }
        free((char*)filepath);
    }
}

extern "C" void pause_session()
{
    torrent_session.pause();
}

// Get torrent struct representing the torrent itself
extern "C" TorrentInfo torrent_get_info(int index)
{
    try {
        lt::torrent_status const& status = torrents.at(index).handler.status();
        lt::torrent_handle& handler = torrents.at(index).handler;
        const lt::torrent_info* info = handler.torrent_file().get();

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

        if (info != NULL) {
            torrent_info.comment = info->comment().c_str();
            torrent_info.creator = info->creator().c_str();
            torrent_info.piece_size = info->piece_length();
            torrent_info.num_pieces_total = info->num_pieces();
            torrent_info.created_on = info->creation_date();

            // Update the name of the torrent
            torrents.at(index).name = status.name;
        } else {
            torrent_info.comment = "";
            torrent_info.creator = "";
            torrent_info.piece_size = 0;
            torrent_info.num_pieces_total = 0;
            torrent_info.created_on = -1;

            // Update the name of the torrent
            load_names_if_required();
            torrents.at(index).name = get_name(torrents.at(index).info_hash);
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
        torrent_info.added_on = (double)status.added_time;
        torrent_info.completed_on = (double)status.completed_time;

        return torrent_info;
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch torrent info." << index << std::endl;

        TorrentInfo torrent_info;
        return torrent_info;
    }
}

// Fetch list of peers
extern "C" void torrent_fetch_peers(int index)
{
    try {
        lt::torrent_handle& handler = torrents.at(index).handler;

        handler.get_peer_info(peers);

        // Destroy previously created peer infos
        for (PeerInfo peer_info : peer_infos) {
            free((char*)peer_info.ip_address);
        }

        peer_infos.clear();

        for (auto it = peers.begin(); it != peers.end(); it++) {
            PeerInfo peer_info = PeerInfo();

            std::stringstream address_ss;
            address_ss << it->ip.address();

            if (it->ip.address().is_v4()) {
                peer_info._ip_address = it->ip.address().to_v4().to_ulong();
            } else {
                peer_info._ip_address = 0;

                boost::asio::ip::address_v6::bytes_type bytes = it->ip.address().to_v6().to_bytes();
                for (int i = 0; i < bytes.size(); i++) {
                    peer_info._ip_address += bytes.at(i);
                }
            }

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
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch torrent peers." << index << std::endl;
    }
}

extern "C" PeerInfo* torrent_get_peer_info(int peer_index)
{
    try {
        return &peer_infos.at(peer_index);
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch peer info." << std::endl;

        return nullptr;
    }
}

extern "C" int torrent_peers_count()
{
    return (int)peers.size();
}

extern "C" void torrent_pause(int index)
{
    try {
        torrents.at(index).handler.unset_flags(lt::torrent_flags::stop_when_ready);
        torrents.at(index).handler.unset_flags(lt::torrent_flags::auto_managed);
        torrents.at(index).handler.pause();
    } catch (std::out_of_range) {
        std::cout << "Failed to pause torrent." << std::endl;
    }
}

extern "C" void torrent_resume(int index)
{
    try {
        torrents.at(index).handler.unset_flags(lt::torrent_flags::stop_when_ready);
        torrents.at(index).handler.set_flags(lt::torrent_flags::auto_managed, lt::torrent_flags::auto_managed);
        torrents.at(index).handler.resume();
    } catch (std::out_of_range) {
        std::cout << "Failed to resume torrent." << std::endl;
    }
}

extern "C" void torrent_force_recheck(int index)
{
    try {
        torrents.at(index).handler.force_recheck();
    } catch (std::out_of_range) {
        std::cout << "Failed to force recheck torrent." << std::endl;
    }
}

extern "C" void torrent_force_reannounce(int index)
{
    try {
        torrents.at(index).handler.force_reannounce(0);
    } catch (std::out_of_range) {
        std::cout << "Failed to force reannounce torrent." << std::endl;
    }
}

extern "C" bool torrent_is_paused(int index)
{
    int64_t flags;
    int64_t mask = 0x0000000000000010;

    try {
        flags = (int)torrents.at(index).handler.flags();

        if ((flags & mask) == mask)
            return true;
        else
            return false;
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch flags to determine if a torrent is paused or not." << std::endl;

        return false;
    }
}

extern "C" bool torrent_is_sequential(int index)
{
    int64_t flags;
    int64_t mask = 0x0000000000000200;

    try {
        auto& handler = torrents.at(index).handler;
        flags = (int)handler.flags();

        auto num_pieces = handler.torrent_file()->num_pieces();
        auto last_piece_index = num_pieces - 1;
        auto last_piece_priority = handler.piece_priority(last_piece_index);
        auto first_piece_priority = handler.piece_priority(0);

        if (num_pieces >= 2) {
            auto second_piece_priority = handler.piece_priority(1);
            auto second_last_piece_priority = handler.piece_priority(num_pieces - 2);

            if (!(second_piece_priority == libtorrent::top_priority && second_last_piece_priority == libtorrent::top_priority))
                return false;
        }

        if ((flags & mask) == mask && last_piece_priority == libtorrent::top_priority && first_piece_priority == libtorrent::top_priority)
            return true;
        else
            return false;
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch flags to determine if a torrent is sequential or not." << std::endl;

        return false;
    }
}

extern "C" void torrent_sequential(int index, bool sequential)
{
    try {
        lt::torrent_handle& handler = torrents.at(index).handler;

        auto num_pieces = handler.torrent_file()->num_pieces();

        if (sequential) {
            handler.set_flags(lt::torrent_flags::sequential_download, lt::torrent_flags::sequential_download);

            // Give first and last two pieces the highest priority
            handler.piece_priority(0, libtorrent::top_priority);

            if (num_pieces >= 2) {
                handler.piece_priority(1, libtorrent::top_priority);
                handler.piece_priority(num_pieces - 2, libtorrent::top_priority);
            }

            handler.piece_priority(num_pieces - 1, libtorrent::top_priority);
        } else {
            handler.unset_flags(lt::torrent_flags::sequential_download);

            // Reset priorities of first and last two pieces
            handler.piece_priority(0, libtorrent::default_priority);

            if (num_pieces >= 2) {
                handler.piece_priority(1, libtorrent::default_priority);
                handler.piece_priority(num_pieces - 2, libtorrent::default_priority);
            }

            handler.piece_priority(num_pieces - 1, libtorrent::default_priority);
        }
    } catch (std::out_of_range) {
        std::cout << "Failed to set/unset torrent to sequential." << std::endl;
    }
}

extern "C" void torrent_remove(int index)
{
    try {
        lt::torrent_handle& handler = torrents.at(index).handler;

        // Remove torrent from session
        torrent_session.remove_torrent(handler);

        // Remove torrent from unordered map
        torrents.erase(index);

        // Remove resume data of torrent
        std::string encoded_hash = hex_encode_sha1_hash(handler.info_hash());

        std::string resume_file = app_data_dir + "/resume_files/" + encoded_hash + ".resume";

        std::ifstream infile(resume_file);
        if (infile.good()) {
            if (std::remove(resume_file.c_str()) != 0) {
                std::cout << "Failed to remove resume file." << std::endl;
            }
        }
    } catch (std::out_of_range) {
        std::cout << "Failed to remove torrent" << std::endl;
    }
}

int get_torrent_from_hash(lt::sha1_hash& hash)
{
    for (auto it = torrents.begin(); it != torrents.end(); ++it) {
        if (it->second.handler.info_hash() == hash) {
            return it->first;
        }
    }

    return -1;
}

extern "C" int get_torrent_from_file(const char* loadPath)
{
    lt::torrent_info info = lt::torrent_info(std::string(loadPath));
    lt::sha1_hash hash = info.info_hash();

    return get_torrent_from_hash(hash);
}

extern "C" int get_torrent_from_magnet_uri(const char* magnet_uri)
{
    lt::add_torrent_params params = lt::parse_magnet_uri(magnet_uri);
    lt::sha1_hash hash = params.info_hashes.get_best();

    return get_torrent_from_hash(hash);
}

extern "C" int torrent_next_index()
{
    return next_index;
}

extern "C" TorrentPieces torrent_pieces(int index)
{
    try {
        // torrent
        Torrent& torrent = torrents.at(index);

        // pieces
        lt::typed_bitfield<lt::piece_index_t> pieces = torrent.handler.status().pieces;

        // Get the download queue
        std::vector<lt::partial_piece_info> queue;
        torrent.handler.get_download_queue(queue);

        // update the piece info of the torrent
        torrent.pieces.count = pieces.size();
        torrent.pieces.content = (piece_state_t*)realloc(torrent.pieces.content, pieces.size() * sizeof(piece_state_t));

        // construct the array
        for (int i = 0; i < torrent.pieces.count; i++) {
            if (pieces[i])
                torrent.pieces.content[i] = piece_finished;
            else
                torrent.pieces.content[i] = piece_unknown;
        }

        for (auto it = queue.begin(); it != queue.end(); it++) {
            torrent.pieces.content[it->piece_index] = piece_downloading;
        }

        return torrent.pieces;
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch torrent pieces" << std::endl;
    }

    return TorrentPieces();
}

extern "C" void debug(int selection)
{
    if (torrent_count() >= 1) {
        try {
            const lt::torrent_info* info = torrents.at(selection).handler.torrent_file().get();

            lt::file_storage files = info->files();

            int num_files = files.num_files();
            std::cout << "Number of files: " << num_files << std::endl;

            std::cout << "Files: " << std::endl;
            for (int i = 0; i < num_files; i++) {
                std::cout << i << ". " << files.file_path(i) << " -> " << files.file_name(i) << std::endl;
            }

            std::cout << "Paths: " << std::endl;

            std::vector<std::string> paths = files.paths();

            for (auto it = paths.begin(); it != paths.end(); it++) {
                std::cout << "Path: " << *it << std::endl;
            }
        } catch (std::out_of_range) {
            std::cout << "Debug error" << std::endl;
        }
    }
}

extern "C" void save_resume_data(int index)
{
    try {
        Torrent torrent = torrents.at(index);
        if (torrent.handler.need_save_resume_data()) {
            torrent.handler.save_resume_data(lt::torrent_handle::flush_disk_cache | lt::torrent_handle::save_info_dict | lt::torrent_handle::only_if_modified);
        }
    } catch (std::out_of_range) {
        std::cout << "Failed to save resume data." << std::endl;
    }
}

extern "C" void save_all_resume_data()
{
    for (std::pair<int, Torrent> torrent : torrents) {
        save_resume_data(torrent.first);
    }
}

extern "C" void set_app_data_dir(const char* dir)
{
    app_data_dir = std::string(dir);
}

void monitor_alerts()
{
    while (true) {
        // retrieve the alerts
        std::vector<lt::alert*> alerts;
        torrent_session.pop_alerts(&alerts);

        for (lt::alert* alert : alerts) {
            switch (alert->type()) {
            case lt::save_resume_data_alert::alert_type: {
                lt::save_resume_data_alert const* srd_alert = lt::alert_cast<lt::save_resume_data_alert>(alert);

                write_torrent_resume_file(srd_alert->handle, srd_alert->params);

                break;
            }
            }
        }

        if (stop_alert_monitor) {
            break;
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
    try {
        Torrent torrent = torrents.at(index);
        torrent.handler.set_download_limit(rate_limit);
    } catch (std::out_of_range) {
        std::cout << "Failed to set download rate limit." << std::endl;
    }
}

extern "C" void torrent_set_upload_rate_limit(int index, int rate_limit)
{
    try {
        Torrent torrent = torrents.at(index);
        torrent.handler.set_upload_limit(rate_limit);
    } catch (std::out_of_range) {
        std::cout << "Failed to set upload rate limit." << std::endl;
    }
}

const std::vector<std::string> explode(const std::string& s, const char& c)
{
    std::string buff { "" };
    std::vector<std::string> v;

    for (auto n : s) {
        if (n != c)
            buff += n;
        else if (n == c && buff != "") {
            v.push_back(buff);
            buff = "";
        }
    }
    if (buff != "")
        v.push_back(buff);

    return v;
}

const std::string implode(std::vector<std::string>& segments, const char& c)
{
    std::string value;
    for (std::string segment : segments) {
        value += segment + c;
    }

    return value;
}

extern "C" void torrent_content_destroy(Content content)
{
    for (int i = 0; i < content.count; i++) {
        ContentItem* item = content.items[i];
        delete[] item->name;
        free(content.items[i]);
    }

    free(content.items);
}

int content_item_find(std::string name, int level, ContentItem** content_items, int content_items_count)
{
    for (int i = 0; i < content_items_count; i++) {
        if (strcmp(name.c_str(), content_items[i]->name) == 0 && content_items[i]->level == level) {
            return i;
        }
    }

    return -1;
}

extern "C" Content torrent_get_content(int index)
{
    try {
        const lt::torrent_info* info = torrents.at(index).handler.torrent_file().get();

        if (info == NULL) {
            return Content();
        }

        lt::file_storage files = info->files();
        ContentItem** content_items = (ContentItem**)malloc(0);
        int id = 0;

        // Go through all the files
        for (auto i : files.file_range()) {
            std::vector<std::string> segments = explode(files.file_path(i), '/');

            if (segments.size() > 0) {
                // Take the file name and remove it from segments
                std::string file_name = segments[segments.size() - 1];
                segments.pop_back();

                // Process all the segments
                int level = 0;
                for (auto it = segments.begin(); it != segments.end(); it++) {
                    if (content_item_find(*it, level, content_items, id) == -1) {
                        ContentItem* item = new ContentItem();

                        // name
                        item->name = c_string(*it);

                        // parent
                        if (it == segments.begin()) {
                            item->parent = -1;
                        } else {
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
                        content_items = (ContentItem**)realloc(content_items, sizeof(ContentItem*) * id);
                        content_items[id - 1] = item;
                    }
                    level++;
                }

                // Process the file segment
                ContentItem* item = new ContentItem();

                // name
                item->name = c_string(file_name);

                // parent
                if (segments.size() == 0) {
                    item->parent = -1;
                } else {
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
                content_items = (ContentItem**)realloc(content_items, sizeof(ContentItem*) * id);
                content_items[id - 1] = item;
            }
        }

        Content content;
        content.items = content_items;
        content.count = id;

        return content;
    } catch (std::out_of_range) {
        std::cout << "Error trying to get content of torrent" << std::endl;
    }

    Content content;
    return content;
}

extern "C" ContentItemInfo torrent_item_info(int index, int item_index)
{
    try {
        Torrent torrent = torrents.at(index);

        ContentItemInfo info;
        info.priority = (int)torrent.handler.file_priority(item_index);
        info.size = (float)torrent.handler.torrent_file()->files().file_size(item_index);
        try {
            info.progress = (float)torrent.files_progress.at(item_index);
        } catch (std::out_of_range) {
            info.progress = 0;
        }

        std::string save_path = torrent.save_path;
        info.path = c_string(torrent.handler.torrent_file()->files().file_path(item_index, save_path));

        std::vector<std::string> segments = explode(info.path, '/');
        if (segments.size() == 1) {
            info.parent_path = "/";
        } else {
            segments.pop_back();
            info.parent_path = c_string("/" + implode(segments, '/'));
        }

        return info;
    } catch (std::out_of_range) {
        std::cout << "Failed to get torrent content item info." << std::endl;
    }

    return ContentItemInfo();
}

extern "C" const char* torrent_get_first_root_content_item_path(int index)
{
    Content content = torrent_get_content(index);
    if (content.count > 0) {
        ContentItem* content_item = content.items[0];

        const char* _path = torrent_item_info(index, content_item->id).path;
        char* path = (char*)calloc(strlen(_path), sizeof(char));
        strcpy(path, _path);

        torrent_content_destroy(content);

        return (const char*)path;
    } else {
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
    try {
        Torrent& torrent = torrents.at(index);
        torrent.handler.file_progress(torrent.files_progress);
    } catch (std::out_of_range) {
        std::cout << "Failed to fetch torrent files' progress" << std::endl;
    }
}

extern "C" void torrent_file_priority(int index, int item_index, int priority)
{
    try {
        Torrent torrent = torrents.at(index);

        torrent.handler.file_priority(item_index, priority);
    } catch (std::out_of_range) {
        std::cout << "Failed to set torrent content item priority." << std::endl;
    }
}

extern "C" void load_geo_ip_database(const char* location)
{
    open_db(location, &mmdb);
}

extern "C" void terminate()
{
    // Queue up resume data to be saved
    save_all_resume_data();

    // Stop alert monitor after finishing up the queued tasks
    stop_alert_monitor = true;
    alert_monitor.get()->join();

    // Abort the session
    lt::session_proxy proxy = torrent_session.abort();

    // Close GeoIP database
    close_db(&mmdb);
    exit(0);
}

extern "C" const char* peer_get_country(const char* ip_address)
{
    const char* country;
    if (get_country(&mmdb, ip_address, &country)) {
        return country;
    } else {
        return (const char*)malloc(0 * sizeof(char));
    }
}

extern "C" void torrent_trackers_destroy(Trackers trackers)
{
    for (int i = 0; i < trackers.count; i++) {
        free((char*)trackers.items[i]->url);
        free(trackers.items[i]);
    }
    free(trackers.items);
}

extern "C" Trackers torrent_get_trackers(int index)
{
    try {
        Torrent torrent = torrents.at(index);

        std::vector<lt::announce_entry> _trackers = torrent.handler.trackers();

        torrent_trackers_destroy(trackers);

        trackers.items = (TrackerInfo**)calloc(_trackers.size(), sizeof(TrackerInfo));
        trackers.count = (int)_trackers.size();

        int i = 0;
        for (lt::announce_entry _tracker : _trackers) {
            TrackerInfo* tracker = new TrackerInfo;
            tracker->url = c_string(_tracker.url);
            tracker->tier = (unsigned char)_tracker.tier;
            tracker->is_working = false;
            tracker->message = (const char*)malloc(0);
            tracker->is_updating = false;
            tracker->seeds = 0;
            tracker->peers = 0;
            tracker->downloaded = 0;

            for (lt::announce_endpoint& endpoint : _tracker.endpoints) {
                for (auto& announce_infohash : endpoint.info_hashes) {
                    if (announce_infohash.scrape_complete != -1)
                        tracker->seeds += announce_infohash.scrape_complete;

                    if (announce_infohash.scrape_incomplete != -1)
                        tracker->peers += announce_infohash.scrape_incomplete;

                    if (announce_infohash.scrape_downloaded != -1)
                        tracker->downloaded += announce_infohash.scrape_downloaded;

                    if (announce_infohash.message.size() >= 1) {
                        free((char*)tracker->message);
                        tracker->message = c_string(announce_infohash.message);
                    }

                    if (announce_infohash.start_sent && announce_infohash.fails == 0)
                        tracker->is_working = true;

                    if (announce_infohash.updating)
                        tracker->is_updating = true;
                }
            }

            trackers.items[i] = tracker;
            i++;
        }

        return trackers;
    } catch (std::out_of_range) {
        std::cout << "Failed to get trackers list." << std::endl;

        return trackers;
    }
}

extern "C" TrackerInfo torrent_tracker_info(int item_index)
{
    try {
        return *trackers.items[item_index];
    } catch (std::out_of_range) {
        std::cout << "Failed to get tracker." << std::endl;

        return TrackerInfo();
    }
}

extern "C" Availability torrent_get_availability(int index)
{
    try {
        Torrent torrent = torrents.at(index);

        std::vector<int> _availability;
        torrent.handler.piece_availability(_availability);

        Availability availability;
        availability.content = (piece_state_t*)calloc(_availability.size(), sizeof(piece_state_t));
        availability.count = (int)_availability.size();
        int available_pieces_count = 0;

        int i = 0;
        for (int piece_availability : _availability) {
            available_pieces_count += piece_availability;

            if (piece_availability) {
                availability.content[i] = piece_finished;
            } else {
                availability.content[i] = piece_unknown;
            }
            i++;
        }

        if (availability.count != 0) {
            availability.value = float(available_pieces_count) / float(availability.count);
        } else {
            availability.value = 0;
        }

        return availability;
    } catch (std::out_of_range) {
        std::cout << "Failed to get torrent availability." << std::endl;
        return Availability();
    }
}

extern "C" void add_extra_trackers_from_magnet_uri(const char* magnet_uri, int index)
{
    lt::add_torrent_params params = lt::parse_magnet_uri(magnet_uri);

    try {
        Torrent& torrent = torrents.at(index);

        for (std::string& tracker : params.trackers) {
            lt::announce_entry entry;
            entry.url = tracker;
            entry.source = entry.source_magnet_link;
            torrent.handler.add_tracker(entry);
        }
    } catch (std::out_of_range) {
        std::cout << "Failed to add extra trackers to torrent.\n";
    }
}

extern "C" void add_extra_trackers_from_file(const char* file_path, int index)
{
    lt::torrent_info info = lt::torrent_info(std::string(file_path));

    try {
        Torrent& torrent = torrents.at(index);

        for (lt::announce_entry tracker : info.trackers()) {
            torrent.handler.add_tracker(tracker);
        }
    } catch (std::out_of_range) {
        std::cout << "Failed to add extra trackers to torrent.\n";
    }
}

extern "C" void configure_libtorrent()
{
    lt::settings_pack pack = torrent_session.get_settings();
    pack.set_int(pack.active_downloads, -1);
    pack.set_int(pack.connections_limit, 1000);
    pack.set_int(pack.active_seeds, -1);
    torrent_session.apply_settings(pack);
}
