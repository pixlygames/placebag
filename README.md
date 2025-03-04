# PlaceBag - QBCore Resource

A QBCore resource that allows admins to place bags/items on the ground with persistent blips for other player to discover.

## Features

- Admin command to place bags with items on the ground
- Configurable item types (drugs, weapons, valuables, etc.)
- Persistent blips that remain after server restarts
- SQL database storage for all placed bags
- Different prop models for different item types
- Random item selection based on configured chances
- Easy collection by players with progress bar animation
- Admin command to reload all bags

## Installation

1. Copy the `placebag` folder to your server's resources directory
2. Import the `placed_bags.sql` file to your database
3. Add `ensure placebag` to your server.cfg
4. Restart your server or start the resource manually

## Usage

### Admin Commands

- `/placebag [type]` - Place a bag with items of the specified type
  - Example: `/placebag drugs` or `/placebag weapons` or `/placebag valuables`
- `/reloadbags` - Reload all placed bags from the database (Admin Only)

### Player Commands

- `/refreshbags` - Refresh all bags for the current player (useful if bags aren't showing)

### Configuration

You can configure the following in the `config.lua` file:

- Admin groups that can use the commands
- Blip settings (sprite, color, scale, etc.)
- Prop settings (default prop model, rotation)
- Item types and their properties:
  - Available items for each type
  - Chance of each item being selected
  - Amount ranges for each item
  - Custom blip colors and names for each item
  - Custom prop models for each item type

### Database Management

The script uses a SQL table called `placed_bags` to store all placed bags. If you delete entries from this table, the corresponding bags and blips will be removed from the game.

## Example Configuration

The default configuration includes examples for:

- Drugs (weed, cocaine, meth)
- Weapons (pistol, SMG, shotgun, ammo)
- Valuables (marked bills, gold bars, diamonds)

You can add your own item types and items by editing the `config.lua` file.

## Dependencies

- QBCore Framework
- oxmysql
- qb-target (for interaction)

### Troubleshooting

If bags are not appearing after server restart:
1. Use the `/refreshbags` command to force reload all bags for your character
2. Make sure you have the latest version of the script with the persistence fixes
3. Check the server console for any error messages
4. Verify that the bags exist in the database 
