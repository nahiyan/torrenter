#include "torrenter/names_database.h"
#include "torrenter/torrents.h"
#include <iostream>
#include <fstream>

std::unordered_map<std::string, std::string> names;
bool requires_loading = true;

std::unordered_map<std::string, std::string> const get_names()
{
    return (std::unordered_map<std::string, std::string> const)names;
}

std::string const get_name(std::string hash)
{
    try
    {
        return names.at(hash);
    }
    catch (std::out_of_range)
    {
        return "";
    }
}

void add_name(std::string hash, std::string name)
{
    try
    {
        names.insert(std::make_pair(hash, name));
    }
    catch (std::out_of_range)
    {
    }
}

void set_name(std::string hash, std::string name)
{
    names.insert_or_assign(hash, name);
}

void remove_name(std::string hash)
{
    try
    {
        names.erase(hash);
    }
    catch (...)
    {
    }
}

void load_names()
{
    names.clear();

    std::ifstream names_db(std::string(get_app_data_dir()) + "/names.db");
    char c;
    std::string buffer, hash, name;

    while (names_db.get(c))
    {
        // Start of string
        if (c == ':')
        {
            int size = std::stoi(buffer);
            buffer = "";
            char string[size + 1];

            for (int i = 0; i < size; i++)
            {
                char c;
                names_db.get(c);
                string[i] = c;
            }
            string[size] = '\0';

            if (size == 40)
            {
                hash = string;
            }
            else
            {
                name = string;
                add_name(hash, string);
            }
        }
        else
        {
            buffer += c;
        }
    }

    names_db.close();

    requires_loading = false;
}

void load_names_if_required()
{
    if (requires_loading)
    {
        load_names();
    }
}

void save_names()
{
    requires_loading = true;

    std::ofstream names_db(std::string(get_app_data_dir()) + "/names.db");

    for (std::pair<std::string, std::string> name : names)
    {
        names_db << "40:" << name.first << name.second.size() << ":" << name.second;
    }
    names_db.close();
}