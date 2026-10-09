# CurseForge project page

Paste these into the project form at https://authors.curseforge.com/#/projects/create

- **Game:** World of Warcraft
- **Project type:** Addons
- **Name:** Dynamic Immersive UI
- **Primary category:** Miscellaneous
- **Additional category:** Map & Minimap
- **License:** MIT License
- **Source:** https://github.com/rubens-lopes/DynamicImmersiveUI
- **Issues:** https://github.com/rubens-lopes/DynamicImmersiveUI/issues

## Summary

The UI hides like Alt+Z and comes back only for combat, a target or a window. Map, bags, loot and chat on their own; no map arrow.

## Description

Dynamic Immersive UI is for players who want to see the world, not the interface. For World of Warcraft: Forever. A companion to Dynamic Display Nameplate.

**How it works**

- Out of combat, the whole UI hides, the way Alt+Z hides it.
- It comes back when combat starts, while you have a living target, or while a window is open (character sheet, spellbook, quests, vendors, the game menu…).
- Being in a group doesn't bring it back; only combat does. A dead target doesn't either: only the loot window shows.
- The world map, the loot window and your bags show on their own, with the rest of the UI still hidden.
- Chat works with the UI hidden: press Enter and type. It fades away 5 seconds after you're done.
- Tooltips, the breath bar and the yellow quest progress text always show.
- Your arrow on the world map is hidden.
- Esc brings the UI back until something changes; Esc again opens the game menu.

**Options**

Every switch is in the options panel: type `/dui-options`, or Esc > Options > AddOns > Dynamic Immersive UI. All start on.

- **Hide the UI out of combat**
- **A target brings the UI back**
- **Map, loot window and bags on their own**
- **Hide your arrow on the world map**

**Commands**

- `/dui-help` lists the commands.
- `/dui-options` opens the options panel.
- `/dui-hide`, `/dui-target`, `/dui-solo`, `/dui-arrow` each take `on` or `off`; with no argument they toggle.
- `/dui-status` shows what the addon sees. Include it in bug reports.

Settings are saved per account.

**Thanks**

To Denthead, whose comment asking for Azerite UI's Explorer Mode and a hidden map arrow started this addon.

**Compatibility**

- World of Warcraft: Forever (1.60.x)

**Source and issues**

The code is on [GitHub](https://github.com/rubens-lopes/DynamicImmersiveUI). If something goes wrong, open an issue there and include the `/dui-status` output.
