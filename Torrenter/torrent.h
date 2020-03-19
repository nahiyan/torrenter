//
//  wrapper.h
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/08/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

#ifndef torrent_h
#define torrent_h

#include <string>
#include <memory>

#include "libtorrent/torrent_handle.hpp"
#include "wrapper.h"

struct Torrent
{
    lt::torrent_handle handler;
    std::string name;
    std::string save_path;
    TorrentPieces pieces;
};

#endif /* torrent_h */
