# Dangling Actor References in Objects
## The Background
UnrealScript mixes C++ and Java paradigms for controlling object lifetime. On one hand, you can explicitly destroy actors (`A.Destroy()`), freeing the memory. On the other hand, it triggers the Garbage Collector to free objects you forgot to delete (or that you weren't given an opportunity to delete).

Here is the root cause of all issues with dangling references:
```js
class ReferencedActor extends Actor;
function doSomething();

// MyActor.uc
class MyActor extends Actor;
var ReferencedActor A;

// MyObject.uc
class MyObject extends Object;
var ReferencedActor A;

//initialization in the code:
var ReferencedActor ref;
ref = spawn(class'ReferencedActor');
MyAct.A = ref;  // MyAct - an instance of MyActor
MyObj.A = ref;  // MyObj - an instance of MyObject
// ...

ref.Destroy();
// ref is MARKED to be destroyed (bDeleteMe=true).
// ref still exists until the end of this tick.
// ref might exist even longer - the memory is freed in batches. ref lives until the next batch is ready.

// A few moments later...
// Now ref is actually deleted (via the Engine's C++ delete operator).

// The Engine clears all references to deleted actors to none,
// but it does that INSIDE OTHER ACTORS only!!!
if (MyAct.A != none)        // false, A == none
    MyAct.A.doSomething();  // the line is skipped

if (MyObj.A != none)        // true, as deleted actor references inside OBJECTS are not cleared.
    MyObj.A.doSomething();  // Crash due to accessing a dangling reference to a non-existent actor
```

## Garbage Collection Crashes on Dangling References
Even if we hadn't called `MyObj.A.doSomething();`, the game would still crash in the GC phase (e.g., on map change). For some reason, the garbage collector accesses the dangling pointer natively and triggers a crash. Some sort of guard exists in the native code, since it doesn't lead to classic Undefined Behavior in C++ when it dereferences a freed memory pointer. The Engine detects the dangling reference, writes the error to KillingFloor.log, and then crashes *deliberately*. But it doesn't tell us which Object and which reference were dangling. Simply "fix your code".
"Thanks", Tim!

By the way, exiting the game doesn't trigger the crash, because GC runs in a different mode during exit without dereferencing pointers.

## WeaponFire is an exception
```js
class WeaponFire extends Object
// ...
var() Weapon Weapon;
var pawn Instigator;
var LevelInfo Level;
var Actor Owner;
```
WeaponFire is an Object, not an Actor, and it's linked to its weapon and pawn (player or bot). Following that logic, the game would crash every time a player dies or drops a weapon. But it doesn't. Because WeaponFire gets *special* treatment. Like actors, WeaponFire's references get cleared when the referenced actor's deleted. Feel free to store anything inside WeaponFire and its descendants with no consequences.

## Access None is Safe
```js
// A stupid example - don't repeat at home, but it does NOT crash.
if (MyAct == none)
    MyAct.A.doSomething();  // logs `Accessed None` and continues
```
The dangling references may exist only inside objects. Actors can even access them and continue working. Don't abuse it - polluting the KillingFloor.log is bad, but use it to your advantage when the referenced actor MUST exist according to your logic.

For example, ScrN Balance *requires* that all human players be controlled by `ScrnPlayerController` or its descendants. So we don't check if the `ScrnPlayerController(PC)` typecast failed - it MUST NOT, according to ScrN logic. If a server is running a mutator that replaces the player controller class with `SomeCrappyController`, they will get many warnings in the log - exactly what we want in a misconfiguration case.

### Rule of Thumb
- Check actors for none if that's a normal case, e.g., checking `if (ScrnGameReplicationInfo(Level.GRI) != none)` in the code that also runs in Story Mode.
- Don't check if the actor MUST NOT be none, for example, `TSCGameReplicationInfo(Level.GRI)` in TSC-only code.

# The Long Dark Road To The Solution
## ScrN Features
A long time ago, players were reporting crashes after opening the "ScrN Features" page on the main menu (`ScrnTab_UserSettings`). "Of course", the crash didn't happen immediately after opening or closing the page, so it took us *years* to find the root cause. But we did have a common pattern: people who opened `ScrnTab_UserSettings` crashed far more often than those who didn't.

The problem was the `PRIArray` cache. `ScrnTab_UserSettings` saved it to speed up player name processing, but because GUIs are Objects, not Actors, its PRI references dangle if any players leave the server mid-game. I fixed the crash without understanding the root cause. By trying everything one by one, we noticed that removing the PRI cache drastically reduced the crash rate. So the fix was there, but the knowledge was still far, far away.

```md
### v9.20
* Added log debug output to help identify the crash problem on opening the ScrN Settings menu.
  When your game crashes on ScrN Features tab please submit client's KillingFloor.log.

### v9.22
* Yet another attempt to fix crash on ScrN Features tab.

### v9.31
* Another attempt to fix crash when opening ScrN Features tab

### v9.32
* Another attempt to fix crash when opening ScrN Features tab

### v9.52
* Yet another attempt to fix client crash while opening ScrN Features tab...

### v9.63.08
* Code cleanup: removed log messages from ScrN Features tab
```

## 404 - Voting Handler Not Found
That's where I learned the root cause of the issue. Players were crashing while voting (`MVOTE`). Voting Handler v4.04 added the detailed log output; we identified the problem and implemented the fix in v4.06.
```js
event NotifyLevelChange()
{
    Master.RemoveInteraction(self);
    if ( VHRI != none ) {
        VHRI.myInteraction = none;
        VHRI.Destroy();
        VHRI = none;
    }
}
```
To understand the crash reproduction complexity, the Voting Handler crashed the player on the *second* map change after voting. So, doing an `MVOTE` triggered a crash when switching maps after the next map. However, the player could quit before that or crash before due to a different bug.

Before v4.04, `VHInteraction` didn't remove itself from the interaction list, so it survived the map change. On the next map load, Voting Handler spawned another instance of `VHInteraction`, which replaced the old one. The old one became unreferenced and garbage-collected at the next map change (the one after the next). All that time, the old `VHInteraction` held a dangling reference to `VHRI`, which triggered the GC crash.

> Back then, each ScrN package had its own version numbering, not tied to ScrN Balance. At the time, the latter was v9.63.

v4.04 addressed the removal but didn't touch `VHRI`:
```js
event NotifyLevelChange()
{
    Master.RemoveInteraction(self);
}
```
The client logs mentioned `VHInteraction`, so I thought staying on the list during the map change was causing the crash. Imagine my surprise when the fix meant to stop occasional crashes triggered them on almost every map change! In reality, `RemoveInteraction()` made the `VHInteraction` GC-eligible, which in turn crashed on the `VHRI` dereference. Before v4.04, a player had to stay on the server for 3 maps in a row to crash. With the "fix", a single map change triggered it. This time, I dug deep, found the root cause, and finally fixed it in v4.06.

> Year 2020 brought me COVID, Social Isolation, and knowledge of dangling references in Unreal Objects.

## New DooM
**May 14, 2024**. Scrake Naders released the **Killing Floor 15th Anniversary Update**, introducing the new game mode (New DooM) and, as we found out later, a new dangling reference crash!
I leave it for you to figure out what was wrong here:
```js
Class ScrnGameLength extends Object;
// ..
var array<KFMonster> Bosses;
```
[Killing Floor 15th Anniversary Update Video](https://youtu.be/GAbCsKxt_8s?si=cOaUrtr7cmwUYAVm)

## The Trader Menu
Last but not least. ScrN Balance **v9.74**. At this moment, I know everything about dangling references. I checked the entire ScrN code, every Object. No dangling references. Every Actor that gets assigned in every Object gets properly cleared. But people are still crashing on garbage collection. I was about to give up: "KF1 is a buggy old game; get used to it", I said. Moreover, most crashes happen on map change, where players have plenty of time to reconnect. Annoying, but tolerable.

Then, I requested the code audit from Claude Opus. No, not "Fix all bugs" or "Game: great, code: good, bugs: no". A slop request would lead to slop results. We spent the entire evening on back-and-forth discussion about project structure, KF1/ScrN specifics, dangling references, and garbage collection. When we were "on the same page", I finally asked to audit the code for potential dangling references. And Opus nailed the task: `ScrnTab_BuyMenu.ScrnPawn` was the one that dangled. The root cause was so deep that it would be impossible for a human to dig out, especially with no idea what to look for or where.

```js
class ScrnTab_BuyMenu extends SRKFTab_BuyMenu;
//...
var transient ScrnHumanPawn ScrnPawn;
//...

function Free()
{
    super.Free();

    // reset all actor references
    LastPerk = none;
    LastVestClass = none;
    PerkLink = none;
    KFPRI = none;
    ScrnPC = none;
    ScrnPawn = none;  // <===== HERE IS OUR HERO

    SelectedItem = none;
    OldPerkClass = none;
    MyAmmos.Length = 0;
    OldPickupClass = none;
}

function ShowPanel(bool bShow)
{
    local ScrnBuyMenuInvList invList;

    super(UT2K4TabPanel).ShowPanel(bShow);

    if ( !bShow ) {
        SetCustomInfoText("");
        SetTimer(0, false);
        return;
    }

    ScrnPC = ScrnPlayerController(PlayerOwner());
    KFPRI = KFPlayerReplicationInfo(ScrnPC.PlayerReplicationInfo);
    PerkLink = Class'ScrnClientPerkRepLink'.Static.FindMe(ScrnPC);
    ScrnPawn = ScrnHumanPawn(ScrnPC.Pawn);  // No read before write. No dangling here and below.
    //...
}
```
The code looked perfectly fine, because it was.
- `ScrnPawn` was assigned on menu show, cleared during the cleanup pass in `Free()`.
- The assignment was done unconditionally: even if ScrnPawn was dangling on entering the trader (e.g., player died => respawned => went to the trader), `ShowPanel()` overwrote it with the valid pawn.
- All assigned actors were cleared in `Free()`; nothing could sneak into the Garbage Collector.

The only problem was that `Free()` was never called for Trader Menu's panels due to a bug in **ServerPerks**:
```js
class SRGUIBuyMenu extends GUIBuyMenu;

function bool NotifyLevelChange()
{
    bPersistent = false;
    return true;
}
```
ServerPerks fixes one issue but introduces another:
- During the game, the Trader Menu doesn't get destroyed on close due to `bPersistent = true` by default. That's correct;
- Vanilla KF keeps the Trader Menu alive even after the game ends and survives map change (that's a bug).
- ServerPerks fixes vanilla bug by setting `bPersistent = false` in `NotifyLevelChange()`, so it gets garbage-collected on map change.
- However, **ServerPerks** doesn't call `super.NotifyLevelChange()`, **breaking ScrN Balance!**
- ServerPerks isn't affected by the issue, as it doesn't use `Free()` in its trader panels.
- ScrN Balance, on the other hand, is left with a dangling `ScrnPawn`, as its `Free()` was never called.
- `ScrnPC`, `PerkLink`, and `KFPRI` were also never cleared, but they never had a chance to become dangling, as they are garbage-collected in the same iteration as `ScrnTab_BuyMenu`.
- GC is performed in two iterations: 1. check references + mark for destruction; 2. the actual destruction. When `ScrnTab_BuyMenu` is checked for references, ScrnPC/PerkLink/KFPRI still exist.

# Skill Issue
> Pro-tip: Never store Actors that may be destroyed during the map in GUI objects.

- The local player controller lives up to map change => GC, so it's OK to link it in GUI.
- The same applies to the **local** PRI (but NOT to other players' PRIs!)

> Pawns, on the other hand, have a bad habit of occasionally dying and getting destroyed.

Storing `ScrnPawn` in a GUI object was a terrible design decision. Especially when I could just use `ScrnPC.ScrnPawn`, which links to the same pawn but never dangles:
- `ScrnPlayerController` is an Actor, so its references (`.ScrnPawn`) get auto-cleared by UE;
- `ScrnPC` has a lifetime of the map and gets GC'd together with GUI.

So it was a skill issue on my part as a developer. From another perspective, it was also a skill issue for players who crashed.

Those players who die a lot and get carried by your team were more likely to crash. If your relative survivability is lower than your teammates', you're prone to crashing. Yes, it was a bug in the code, but at the end of the day, *your skill as a player was a decisive factor in the crash probability.*

Let me explain. An in-object actor reference dangles only after the actor is deleted in the engine (C++ `delete actorPtr;`). `actor.Destroy()` only marks it for deletion (`bDeleteMe = true`). The actor is guaranteed to survive the current Tick; then UE puts it into the "trash bin" and wipes the bin once it's full.
- Players who survive the game keep their pawns until the map change. The latter get garbage-collected together with `ScrnTab_BuyMenu` and never dangle. Surviving the game = no crash (with a rare exception that I'll explain later).
- Players who die last are most likely to save their pawns, too. When the last player dies, the game ends. Your dead body is lying on the ground - that's still a valid `ScrnHumanPawn`, referenced by `ScrnTab_BuyMenu`. Your body is dead, but your "soul" (`ScrnHumanPawn`) keeps ticking.
- Players who stay together and die together are less likely to crash. You died, but your body is still there even after you switch to spectate your teammates. So `ScrnHumanPawn` still exists and follows the logic above.
- If you run away from the team and die, `ScrnHumanPawn` gets destroyed after you switch to a far teammate (no longer see the dead body), so you will crash if the game ends this wave (so you won't respawn and visit the trader to reset `ScrnTab_BuyMenu.ScrnPawn`).
- If you died, respawned next wave, but didn't make it to the trader, `ScrnTab_BuyMenu.ScrnPawn` still holds the dangling references to the old pawn. If the game ends this wave, you'll crash.

At the end of the day, **NOOBS** are the ones who were crashing the most. Run away from the team and die? Crash. Died and didn't make it to the next trader in time? Crash.
