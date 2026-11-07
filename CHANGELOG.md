# Changelog

## v0.4.0

- Your buffs show with the UI hidden, fading in for 5 seconds when you gain or renew one, and while one has less than 30 seconds left. Switch it off with `/dui-buffs off` or in the options panel.
- New key binding to turn hiding on or off: Key Bindings > Dynamic Immersive UI.
- Esc brings the UI back for 5 seconds only; Esc again opens the game menu, and the UI hides when you close it. Alt+Z still brings it back until something changes.
- Fixed: chat closed while you were typing when a fight ended. The UI now waits until you send or close the message.

## v0.3.4

- Fixed: after opening the bank (or a vendor, a quest giver…) with the UI hidden, using an item from your bags was blocked for the rest of the session ("DynamicImmersiveUI has been blocked from an action only available to the Blizzard UI").

## v0.3.3

- New option, off at first: hide your party and raid members on the world map (`/dui-group`). Hiding your arrow now hides only your arrow; before, it hid your group too.
- Pings show in the world with the UI hidden, and chat shows for 5 seconds when someone pings, you too (with the switch for new messages).
- Fixed: with MoveAny, windows first opened more than a minute after logging in, with the UI hidden, showed where the game puts them and couldn't be dragged, until a /reload.
- Fixed: "All options…" in the quick menu, and `/dui-options`, sometimes opened the first page of the game's options instead of this addon's.

## v0.3.2

- Fixed: with the UI hidden, settings opened from an addon's minimap button menu (Frequent Flyer…) didn't show, and the UI flickered.
- Fixed: with the UI hidden, those menus could show with a dark box over their items.

## v0.3.1

- Fixed: with the UI hidden, addon settings opened from the addons button on the minimap (MapUtils, MoveAny…) didn't show. They now show on their own, like a window opened from a minimap button, and Esc closes them.

## v0.3.0

- New options panel, in the same style as the game's own: the switches are grouped under headings, hover one to see what it does, and Defaults puts them all back.
- Quick menu: click the addons button on the minimap, then Dynamic Immersive UI, to turn switches on or off without bringing the UI back.

## v0.2.1

- New option, off at first: action bars show when you move the mouse over them with the UI hidden, one bar at a time, and fade away after. Turn it on with `/dui-bars` or in the options panel. Bars moved with Edit Mode show where you put them.

## v0.2.0

- Chat shows for 5 seconds when a whisper, party or guild message arrives while the UI is hidden. Switch it off with `/dui-messages off` or in the options panel.
- Need/greed rolls show with the UI hidden. A roll you couldn't see used to pass when its timer ran out.
- Fixed: clicking an item link in chat didn't show the item with the UI hidden.

## v0.1.5

- Fixed: bags opened with the UI hidden, the reagent bag especially, were covered by a grey box over their slots.
- Fixed: with MoveAny, windows couldn't be moved and opened where Blizzard puts them instead of where you moved them.

## v0.1.4

- Fixed: opening a letter at a mailbox brought the UI back and closed the mailbox, so you couldn't take its attachments. Letters, and the confirmations they ask for, now show on their own with the mailbox.

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
