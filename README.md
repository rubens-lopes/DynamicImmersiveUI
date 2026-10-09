# Dynamic Immersive UI

A World of Warcraft: Forever addon for immersion. The whole UI hides the way Alt+Z hides it, and comes back only when you need it:

- in combat,
- while you have a living target,
- while a window is open (character sheet, spellbook, quests, vendors, the game menu…).

Being in a group doesn't bring it back; only combat does. A dead target doesn't either: loot it and only the loot window shows.

Out of combat, the world map, the loot window, your bags and any window you open from a minimap button show **on their own**, with the rest of the UI still hidden; Esc closes them. Chat works too: press Enter and type as usual, and chat fades away 5 seconds after you're done. The minimap, tooltips, the breath bar and the yellow quest progress text ("Wolf Pelt: 3/8") always show.

Your arrow on the world map is hidden, so you find your way from the landmarks.

Press Esc to bring the UI back until something changes (a target, a fight, a window); Esc again opens the game menu as usual.

## Options

Open the panel with `/dui-options`, or Esc > Options > AddOns > Dynamic Immersive UI. Every switch starts on.

- **Hide the UI out of combat**: the main switch. Off, the addon leaves the UI alone.
- **A target brings the UI back**: shows the UI while you have a living target.
- **Map, loot window and bags on their own**: also windows opened from a minimap button. Off, these bring the whole UI back like any other window.
- **Minimap always visible**: keeps the minimap on screen while the rest of the UI is hidden.
- **Hide your arrow on the world map**: party and raid members still show.

## Commands

- `/dui-help` lists the commands.
- `/dui-options` opens the options panel.
- `/dui-hide`, `/dui-target`, `/dui-solo`, `/dui-minimap` and `/dui-arrow` take `on` or `off`; with no argument they toggle.
- `/dui-status` shows what the addon sees. Its output is also saved in the addon's saved variables; include it in bug reports.

Settings are saved per account.

## Install

Get it from CurseForge, or copy this folder to `World of Warcraft/_classic_beta_/Interface/AddOns/DynamicImmersiveUI` for the Forever beta.

## Development

```bash
luajit tests/test_addon.lua
```

Tagging `vX.Y.Z` runs the BigWigs packager in GitHub Actions and attaches the zip (`dui-<version>.zip`) to a GitHub Release. Tags containing `beta` or `alpha` become pre-releases. Upload that zip to CurseForge by hand.
