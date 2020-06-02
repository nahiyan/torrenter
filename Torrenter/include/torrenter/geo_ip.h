#ifndef geo_ip_h
#define geo_ip_h

#include "../../include/libmaxminddb/maxminddb.h"

int open_db(const char*, MMDB_s *);
void close_db(MMDB_s *);
int get_country(MMDB_s *, const char *ip_address, const char **country);

#endif
