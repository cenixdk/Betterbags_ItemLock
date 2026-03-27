# BetterBags — Item Lock

A plugin for [BetterBags](https://github.com/BetterBags/BetterBags) that lets you lock items in your bags to prevent accidentally selling them at a vendor.

## Requirements

- [BetterBags](https://github.com/BetterBags/BetterBags)
- World of Warcraft: Midnight (12.x)

## Features

- **Lock/unlock items** with Alt+Click
- **Padlock icon** shown on locked items in the bag
- **Sell prevention** — right-clicking a locked item at a vendor is blocked with an error message
- **Tooltip hint** — hovering an item shows whether it is locked and how to toggle it
- **Persistent** — locked items are remembered across sessions via saved variables

## Usage

| Action | How |
|--------|-----|
| Lock an item | Alt+Click the item in your bag |
| Unlock an item | Alt+Click the item again |
| Sell prevention | Automatic — locked items cannot be right-clicked at a vendor |

A padlock icon appears in the top-left corner of any locked item. The item tooltip shows **Alt+Click to lock** or **Alt+Click to unlock** depending on its current state.

## Installation

1. Download and extract the addon folder
2. Place `BetterBags_ItemLock` in `World of Warcraft/_retail_/Interface/AddOns/`
3. Make sure [BetterBags](https://github.com/BetterBags/BetterBags) is also installed
4. Reload or launch the game

## Notes

- Locking is based on item GUID where available, falling back to bag slot position. This means locks survive bag re-renders but may shift if items are moved manually and the GUID cannot be resolved.
- The disenchant prevention feature is not yet implemented.
