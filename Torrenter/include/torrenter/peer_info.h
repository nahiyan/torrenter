//
//  PeerInfo.h
//  Torrenter
//
//  Created by Nahiyan Alamgir on 3/24/20.
//  Copyright © 2020 Nahiyan Alamgir. All rights reserved.
//

#ifndef PeerInfo_h
#define PeerInfo_h

#include <string>

struct PeerInfo_
{
    std::string ip_address;
    std::string client;
    int up_rate;
    int down_rate;
    long long int total_down;
    long long int total_up;
    float progress;
    int connection_type;
};

#endif /* PeerInfo_h */
