# CurseForge project page

Paste these into the project form at https://authors.curseforge.com/#/projects/create

- **Game:** World of Warcraft
- **Project type:** Addons
- **Name:** Dynamic Immersive UI
- **Primary category:** Miscellaneous
- **Additional category:** Map & Minimap
- **License:** MIT License
- **Logo:** `media/logo.png`
- **Source:** https://github.com/rubens-lopes/DynamicImmersiveUI
- **Issues:** https://github.com/rubens-lopes/DynamicImmersiveUI/issues
- **Images** (Images tab): `antes-depois.jpg`, `antes-com-ui.jpg`, `depois-sem-ui.jpg`, and the GIFs below

The images and clips live outside the repo, in `Videos/DUI` on the Windows machine (`clipes/`, `fotos/`). Upload them in the project's Images tab, then replace each `IMAGE:` placeholder below with the image's CurseForge URL.

## Summary

The UI hides like Alt+Z and comes back only for combat, a target or a window. Map, bags, loot and chat on their own; no map arrow.

## Description

Dynamic Immersive UI is for players who want to see the world, not the interface. For World of Warcraft: Forever. A companion to Dynamic Display Nameplate.

![The same moment with the UI and without it](IMAGE:antes-depois.jpg)

**How it works**

- Out of combat, the whole UI hides, the way Alt+Z hides it.
- It comes back when combat starts, while you have a living target, or while a window is open (character sheet, spellbook, quests, vendors, the game menu…).
- Being in a group doesn't bring it back; only combat does. A dead target doesn't either: only the loot window shows.
- The world map, the loot window, your bags and windows opened from a minimap button show on their own, with the rest of the UI still hidden. Esc closes them.
- So do quests from objects in the world, mailboxes and books: with no target to bring the UI back, they open on their own.
- Chat works with the UI hidden: press Enter and type. It fades away 5 seconds after you're done.
- The minimap, tooltips, the breath bar and the yellow quest progress text always show.
- Your arrow on the world map is hidden.
- Optionally, your action bars show when you move the mouse over them.
- Esc brings the UI back until something changes; Esc again opens the game menu.

**See it in game**

A fight brings the UI back, and it hides again once the fight is over (the fight is sped up):

![Combat](IMAGE:1-combate.gif)

Loot shows on its own:

![Loot](IMAGE:2-loot.gif)

So does the world map, without your arrow:

![World map](IMAGE:3-mapa.gif)

And your bags:

![Bags](IMAGE:4-bolsa.gif)

Other windows, like the character sheet, bring the whole UI back:

![Character sheet](IMAGE:5-ficha.gif)

Optionally, an action bar shows when you move the mouse over it:

![Action bars](IMAGE:6-barras.gif)

**Options**

Every switch is in the options panel: type `/dui-options`, or Esc > Options > AddOns > Dynamic Immersive UI. Hover a switch to see what it does. For a quick change, click the addons button on the minimap, then Dynamic Immersive UI: its switches show in a small menu, without bringing the UI back. All start on, except the action bars on mouseover.

- **Hide the UI out of combat**
- **A target brings the UI back**
- **Map, loot and bags alone** (and windows opened from a minimap button)
- **Minimap always visible**
- **Action bars show on mouseover** (off at first)
- **Chat shows on new messages**
- **Hide your arrow on the map**

**Commands**

- `/dui-help` lists the commands.
- `/dui-options` opens the options panel.
- `/dui-hide`, `/dui-target`, `/dui-solo`, `/dui-minimap`, `/dui-bars`, `/dui-messages`, `/dui-arrow` each take `on` or `off`; with no argument they toggle.
- `/dui-status` shows what the addon sees. Include it in bug reports.

Settings are saved per account.

**Thanks**

To Denthead, whose comment asking for Azerite UI's Explorer Mode and a hidden map arrow started this addon.

**Compatibility**

- World of Warcraft: Forever (1.60.x)

**Source and issues**

The code is on [GitHub](https://github.com/rubens-lopes/DynamicImmersiveUI). If something goes wrong, open an issue there and include the `/dui-status` output.
