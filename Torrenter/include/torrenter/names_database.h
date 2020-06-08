#ifndef names_database_h
#define names_database_h

#include <string>
#include <unordered_map>

void load_names();
void load_names_if_required();
void save_names();
std::unordered_map<std::string, std::string> const get_names();
void add_name(std::string, std::string);
std::string const get_name(std::string);
void set_name(std::string, std::string);
void remove_name(std::string);

#endif