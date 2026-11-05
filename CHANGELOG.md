# Changelog

## v0.1.3

- Fixed: a quest from an object in the world (a table, a wanted poster…) opened empty. Quests, mailboxes and books you open without a target now show on their own, with the UI still hidden.
- Fixed: mailboxes didn't open with the UI hidden. They now open on their own, with your bags.
- Bags open without showing the UI for a moment, so they no longer close the map or other windows shown on their own.
- Fixed: the new-mail icon on the minimap disappeared.
- Fixed: Quick Keybind Mode flickered.

## v0.1.2

- Your cast bar shows with the UI hidden (hearthstone, mounting, crafting…).

## v0.1.1

- Fixed: with DynamicCam installed, nameplates didn't show for a whole fight that started while the UI was hidden.

## v0.1.0-beta2

- Windows opened by clicking a minimap button (addon settings, the dungeon journal…) show on their own instead of bringing the whole UI back.
- Esc closes the bags, map, loot window or minimap window shown on their own, and the UI stays hidden.
- Tooltips no longer show behind the minimap and windows.
- Lua error popups show with the UI hidden.

## v0.1.0-beta1

- First beta for World of Warcraft: Forever.
- The UI hides like Alt+Z out of combat and comes back in combat, with a living target, or while a window is open. Esc brings it back until something changes.
- The world map, the loot window and bags show on their own out of combat. Chat works with the UI hidden and fades 5 seconds after typing. The minimap (`/dui-minimap`), tooltips, the breath bar and quest progress text always show.
- Your arrow on the world map is hidden.
- Options panel (`/dui-options`) and commands: `/dui-hide`, `/dui-target`, `/dui-solo`, `/dui-minimap`, `/dui-arrow`, `/dui-status`, `/dui-help`.
