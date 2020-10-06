# Engine Configuration

Game engines are usually configurable:
* Graphics configs (window sizes, detailing, etc.)
* Audio configs (volume, etc.)
* Development configs (player character maximum walk speed, etc.)

### Restoring Configurations
Configurations are useful only if they can be stored and loaded later.

* Text configuration files
    * The most common method.  Windows has `.ini` files, there is also JSON, XML, etc.
* Compressed binary files
    * This is what you used to use when consoles didn't have a hard drive to store data to.  On memory cards, you'd have to use their binary format to store both configurations, saved games, etc.
* Command-line options and Environment Variables
    * Obviously useful for development, not so much for the final game.
* Online user profiles
    * You can delegate configuration (where appropriate) to a user's profile if you're using an online service like Xbox Live.
    * This will require an Internet connection to load configurations though.
* Per-User options
    * Differentiate between global options and user-level options.
    * On Windows machines, you could store the data in `C:\Users\{User}\AppData`.
    
### Case Studies
* _Quake_ engine
    * Uses _console variables_ aka _cvars_, which are `float` globals that must be interpreted by the engine console.
    * _cvars_ are stored in a global linked list, each containing a `name`, its `value`, a set of `flag bits`, and a pointer to the next _cvar_ in the linked list.
* _OGRE_ engine
    * Uses text files in `ini` format.  There are three such files: `plugins.cfg`, `resources.cfg`, and `ogre.cfg`.
* _Naughty Dog_ engine
    * All options are members of a mutable global struct.
    * They developed an in-game menu system to mutate the global configuration options and even invoke commands.
    * A menu item has the memory address of the variable, and it can directly control its value.
    * Menu settings are saved in an INI-style text file.
