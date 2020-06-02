#include <stdio.h>
#include "../../include/libmaxminddb/maxminddb.h"
#include <locale.h>
#include <stdlib.h>

int open_db(const char *location, MMDB_s *mmdb)
{
    return MMDB_open(location, MMDB_MODE_MMAP, mmdb);
}

void close_db(MMDB_s *mmdb)
{
    MMDB_close(mmdb);
}

int get_country(MMDB_s *mmdb, const char *ip_address, const char **country)
{
    int gai_error, mmdb_error;
    MMDB_lookup_result_s result = MMDB_lookup_string(mmdb, ip_address, &gai_error, &mmdb_error);

    if (gai_error == 0 && mmdb_error == MMDB_SUCCESS)
    {
        if (result.found_entry)
        {
            MMDB_entry_data_s entry_data;
            int status = MMDB_get_value(&result.entry, &entry_data, "country", "names", "en", NULL);
            if (status == MMDB_SUCCESS)
            {
                if (entry_data.has_data)
                {
                    char *country_string = (char *)calloc(entry_data.data_size, sizeof(char));
                    int i;
                    for (i = 0; i < entry_data.data_size; i++)
                    {
                        country_string[i] = entry_data.utf8_string[i];
                    }

                    *country = (const char *)country_string;

                    return 1;
                }
            }
        }
    }

    return 0;
}