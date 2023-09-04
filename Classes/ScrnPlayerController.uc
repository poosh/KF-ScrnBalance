class ScrnPlayerController extends KFPCServ
    config(ScrnUser);

// ScrnPlayerController may possess only ScrnHumanPawn (or descendants).
// Possessing non-ScrnHumanPawn cause undefined behavior
var ScrnHumanPawn ScrnPawn;
var ScrnBalance Mut;
var transient bool bHadPawn;

var byte VeterancyChangeWave; // wave number, when player has changed his perk

var globalconfig bool bManualReload, bOtherPlayerLasersBlue;
var globalconfig bool bAlwaysDisplayAchProgression; // always display a message on any achievement progress
var globalconfig int AchGroupIndex;
var globalconfig int Custom3DScopeSens;

var globalconfig bool bSpeechVote; //allow using speeches Yes and No in voting

struct SWeaponSetting
{
    var globalconfig class<KFWeapon> Weapon;
    var globalconfig byte SkinIndex;
    var transient class<KFWeapon> SkinnedWeapon; //used on server-side only
    var transient KFWeapon LastWeapon; // last weapon on which skin was used
};
var globalconfig array<SWeaponSetting> WeaponSettings;


var transient array<ScrnAchievements.AchStrInfo>PendingAchievements; //earned achievements waiting to be displayed on the HUD
//current achievement object and index to display on the HUD
var transient ScrnAchievements CurrentAchHandler;
var transient int CurrentAchIndex;
var transient bool bWasAchUnlockedJustNow;
var float AchievementDisplayCooldown; // time to wait between displaying achievements, if multiple achievements were earned

var transient class<KFVeterancyTypes> InitialPerkClass;
var bool bChangedPerkDuringGame; // player changed his perk during a game
var transient bool bCowboyForWave;
var transient byte BeggingForMoney; // how many times player asked for money during this wave
var transient bool bShoppedThisWave;
var byte PathDestination; // 0 - trader, 255 - TSC base

var byte MaxVoiceMsgIn10s; // maximum number of voice messages during 10 seconds
var bool bZEDTimeActive;

var bool bHadArmor; //player had armor during the game

var bool bWeaponsLocked; // disables player's weapons pick up by other players
var localized string strLocked, strUnlocked, strLockDisabled;
var transient float LastLockMsgTime; // last time when player received a message that weapon is locked

var localized string strAlreadySpectating;

var globalconfig bool bPrioritizePerkedWeapons, bPrioritizeBoomstick;

var int StartCash; // amount of cash given to this pawn on game/wave start

struct SDualWieldable {
    var class<KFWeapon> Single, Dual;
};
var array<SDualWieldable> DualWieldables;
var private transient bool bDualWieldablesLoaded;

var transient float NextCrapTime;
var transient float LastBlamedTime;


// TSC
var string ProfilePageClassString;
var string TSCLobbyMenuClassString;
var config bool bTSCAdvancedKeyBindings; // pressing altfire while carrying the guardian gnome, sets up the base
var config bool bTSCAutoDetectKeys; // turns off bTSCAdvancedKeyBindings if a dedicated key is bound for SetupBase
var config string RedCharacter, BlueCharacter;

// not replicated yet
// todo: find an efficient way to replicate
var array<string> RedCharacters, BlueCharacters;

var class<ScrnCustomPRI> CustomPlayerReplicationInfoClass;
var ScrnCustomPRI ScrnCustomPRI;
var transient bool bDestroying; // indicates that Destroyed() is executing

var byte DamageAck;  // does server needs to acknowledge client of damages he made?
var ScrnDamageNumbers DamageNumbers;
var class<ScrnDamageNumbers> DamageNumbersClass;

var transient byte PerkChangeWave; // wave num, when perk was changed last time
var localized string strNoPerkChanges, strPerkLocked, strPerkNotAvailable;

var transient Controller FavoriteSpecs[2];
var localized string strSpecFavoriteAssigned, strSpecNoFavorites;
var transient Actor OldViewTarget;

var transient rotator PrevRot;
var transient int ab_warning;

var globalconfig bool bDebugRepLink, bWaveGarbageCollection;
var globalconfig string PlayerName;

// DLC checks
struct SDLC {
    var int AppID;
    var bool bOwnsDLC;
    var bool bChecked;
};
var array<SDLC> DLC;

var transient int AchResetPassword;


struct SMusicRecord {
    var byte PL, Wave;
    var bool bTrader;
    var string Song;
    var string Artist, Title;
};
var globalconfig byte ActiveMusicPlaylist;
var globalconfig array<String> MusicPlaylistNames;
var globalconfig array<SMusicRecord> MyMusic;

var protected transient array<int> MusicPlaylistIndex; // MusicPlaylistIndex[PL] = index of first playlist entry in MyMusic
var protected transient bool bMusicPlaylistIndexReady;
var protected transient int ActiveMusicSongIndex;
var protected transient string PendingSong;
var localized string strPlayingSong;

var class<ScrnFlareCloud> FlareCloudClass;

var transient float LastMutateTime;
var transient int MutateCounter;
var localized string strMutateProtection;

replication
{
    reliable if ( Role == ROLE_Authority )
        ClientMonsterBlamed, ClientPostLogin;

    unreliable if ( Role == ROLE_Authority )
        ClientPlayerDamaged;

    unreliable if ( Role == ROLE_Authority )
        ClientFlareDamage;

    reliable if ( Role < ROLE_Authority )
        SrvAchReset, ResetMyAchievements, ResetMapAch,
        ServerDropAllWeapons, ServerLockWeapons, ServerGunSkin,
        ServerAcknowledgeDamages, ServerShowPathTo,
        ServerDebugRepLink, ServerFixQuickMelee,
        ServerTourneyCheck, ServerKillMut, ServerKillRules,
        ServerSwitchViewMode, ServerSetViewTarget,
        ServerCrap;

    reliable if ( bNetOwner && (bNetDirty || bNetInitial) && Role < ROLE_Authority )
        bPrioritizePerkedWeapons, StartCash;

    // TSC stuff
    reliable if ( Role < ROLE_Authority )
        ServerScoreFlag;
}

simulated function PreBeginPlay()
{
    super.PreBeginPlay();

    class'ScrnMagnum44Fire'.static.PreloadAssets(Level);
    class'ScrnDual44MagnumFire'.static.PreloadAssets(Level);
    class'ScrnMAC10Fire'.static.PreloadAssets(Level);
    class'KFMod.M79Fire'.static.PreloadAssets(Level);
}


// this function is called on on server side only
// and only if using ScrnGameType, ScrnStoryGameInfo or descendants
function PostLogin()
{
    ServerAcknowledgeDamages(DamageAck);
    ClientPostLogin();

    ScrnCustomPRI.GotoState('');
    if ( Level.NetMode == NM_Standalone || (Level.NetMode == NM_ListenServer && Viewport(Player) != None) )
        ScrnCustomPRI.SetSteamID64(Mut.MySteamID64);
    else
        ScrnCustomPRI.SetSteamID64(GetPlayerIDHash());
    ScrnCustomPRI.NetUpdateTime = Level.TimeSeconds - 1;

    if ( PlayerName != "" )
        SetName(PlayerName);

    Mut.GameRules.PlayerEntering(self);
}

simulated function ClientPostLogin()
{
    local ScrnHUD hud;

    hud = ScrnHUD(myHUD);
    if ( hud != none && DamageAck != hud.ShowDamages ) {
        DamageAck = hud.ShowDamages;
        ServerAcknowledgeDamages(DamageAck);
    }
}

simulated function LoadMutSettings()
{
    if ( Mut != none ) {
        if ( Mut.bHardCore )
            bOtherPlayerLasersBlue = false;
    }
    else {
        //this shouldn't happen
        log("Player Controller cannot find ScrnBalance!", 'ScrnBalance');
    }
}

function InitPlayerReplicationInfo()
{
    local LinkedReplicationInfo L;

    super.InitPlayerReplicationInfo();

    for( L=PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo ) {
        if ( ScrnCustomPRI(L) != none )
            return; // wtf?
        if( L.NextReplicationInfo==None )
            break;
    }

    ScrnCustomPRI = spawn(CustomPlayerReplicationInfoClass, self);
    if ( ScrnCustomPRI != none ) {
        if ( PlayerReplicationInfo.CustomReplicationInfo != none )
            ScrnCustomPRI.NextReplicationInfo = PlayerReplicationInfo.CustomReplicationInfo;
        PlayerReplicationInfo.CustomReplicationInfo = ScrnCustomPRI;
    }
    else
        warn("Can not create ScrnCustomPRI: " $ CustomPlayerReplicationInfoClass);
}

//copypaste from KFPlayerController with constant value of 24 replaced by Custom3DScopeSens to set custom sensitivity for 3D scopes
function float GetMouseModifier()
{
    local KFWeapon weap;

    if (Pawn == none || Pawn.Weapon == none)
        return -1.0;

    weap = KFWeapon(Pawn.Weapon);

    if (weap== none )
        return -1.0;

    if(weap.KFScopeDetail == KF_ModelScope && weap.ShouldDrawPortal())
    {
        return Custom3DScopeSens;
    }
    else if(weap.KFScopeDetail == KF_ModelScopeHigh && weap.ShouldDrawPortal())
    {
        return Custom3DScopeSens;
    }
    else
    {
        return -1.0;
    }
}

simulated function ClientForceCollectGarbage()
{
    ConsoleCommand("MEMSTAT", true); // write memory stats into log
    if ( bWaveGarbageCollection ) {
        super.ClientForceCollectGarbage();
        ConsoleCommand("MEMSTAT", true);
    }
}


simulated function PreloadFireModeAssetsSE(class<WeaponFire> WF, optional WeaponFire SpawnedFire)
{
    local class<Projectile> P;//log("ScrnPlayerController.PreloadFireModeAssets()" @ WF, 'ScrnBalance');

    if ( WF == none || WF == Class'KFMod.NoFire' )
        return;


    if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
        class<KFFire>(WF).static.PreloadAssets(Level, KFFire(SpawnedFire));
    else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
        class<KFMeleeFire>(WF).static.PreloadAssets(KFMeleeFire(SpawnedFire));
    else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
        class<KFShotgunFire>(WF).static.PreloadAssets(Level, KFShotgunFire(SpawnedFire));


    // preload projectile assets
    P = WF.default.ProjectileClass;
    //log("Projectile =" @ P, 'ScrnBalance');
    if ( P == none )
        return;

    if ( class<ScrnCustomShotgunBullet>(P) != none )
        class<ScrnCustomShotgunBullet>(P).static.PreloadAssets();
    else if ( class<CrossbuzzsawBlade>(P) != none )
        class<CrossbuzzsawBlade>(P).static.PreloadAssets();
    else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
        class<LAWProj>(P).static.PreloadAssets();
    else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
        class<M79GrenadeProjectile>(P).static.PreloadAssets();
    else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
        class<SPGrenadeProjectile>(P).static.PreloadAssets();
    else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
        class<HealingProjectile>(P).static.PreloadAssets();
    else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
        class<CrossbowArrow>(P).static.PreloadAssets();
    else if ( class<M99Bullet>(P) != none )
        class<M99Bullet>(P).static.PreloadAssets();
    else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
        class<PipeBombProjectile>(P).static.PreloadAssets();
    // More DLC
    else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
        class<SealSquealProjectile>(P).static.PreloadAssets();
}

simulated function ClientWeaponSpawned(class<Weapon> WClass, Inventory Inv)
{
    local class<KFWeapon> W;
    local class<KFWeaponAttachment> Att;
    local Weapon Spawned;

    //log("ScrnPlayerController.ClientWeaponSpawned()" @ WClass $ ". Default Mesh = " $ WClass.default.Mesh, 'ScrnBalance');
    //super.ClientWeaponSpawned(WClass, Inv);

    W = class<KFWeapon>(WClass);
    // preload assets only for weapons that have no static ones
    // damned Tripwire's code doesn't bother for cheking is there ref set or not!
    if ( W != none) {
        //preload weapon assets
        if ( W.default.Mesh == none )
            W.static.PreloadAssets(Inv);
        Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
        // 2013/01/22 EDIT: bug fix
        if ( Att != none && Att.default.Mesh == none ) {
            if ( Inv != none )
                Att.static.PreloadAssets(KFWeaponAttachment(Inv.ThirdPersonActor));
            else
                Att.static.PreloadAssets();
        }
        // 2014-11-23 fix
        Spawned = Weapon(Inv);
        if ( Spawned != none ) {
            PreloadFireModeAssetsSE(W.default.FireModeClass[0], Spawned.GetFireMode(0));
            PreloadFireModeAssetsSE(W.default.FireModeClass[1], Spawned.GetFireMode(0));
        }
        else {
            PreloadFireModeAssetsSE(W.default.FireModeClass[0]);
            PreloadFireModeAssetsSE(W.default.FireModeClass[1]);
        }
    }
}

function PawnDied(Pawn P)
{
    ServerDropFlag();

    super.PawnDied(P);
}


function ShowBuyMenu(string wlTag,float maxweight)
{
    StopForceFeedback();

    ClientOpenMenu(string(Class'ScrnGUIBuyMenu'),,wlTag,string(maxweight));
}


exec function CookGrenade()
{
    if ( ScrnPawn != none )
        ScrnPawn.CookGrenade();
}

exec function ThrowCookedGrenade()
{
    if ( ScrnPawn != none )
        ScrnPawn.ThrowCookedGrenade();
}

exec function QuickMelee()
{
    if ( ScrnPawn != none )
        ScrnPawn.QuickMelee();
}

/**
 * DamTypeNum:
 * 0 - normal
 * 1 - headshot
 * 2 - fire DoT
 * 3 - shot to decapitated body
 * 10 - player damage
 */
function SendDamageAck(int Damage, vector HitLocation, byte DamTypeNum)
{
    local ScrnPlayerController SpecPC;
    local int i;

    ClientPlayerDamaged(Damage, HitLocation, DamTypeNum);

    if ( Role == ROLE_Authority && ScrnPawn != none && ScrnPawn.bViewTarget ) {
        // show damage popups on spectating players
        for ( i=0; i<Level.GRI.PRIArray.length; ++i ) {
            if ( Level.GRI.PRIArray[i] != none && Level.GRI.PRIArray[i].bOnlySpectator ) {
                SpecPC = ScrnPlayerController(Level.GRI.PRIArray[i].Owner);
                if ( SpecPC != none && SpecPC != self && SpecPC.ViewTarget == Pawn )
                    SpecPC.ClientPlayerDamaged(Damage, HitLocation, DamTypeNum);
            }
        }
    }
}

function DamageMade(int Damage, vector HitLocation, byte DamTypeNum, optional Pawn Victim,
        optional class<DamageType> DamType)
{
    if ( DamageAck == 0 )
        return;

    if ( DamageAck == 2 || Victim == none || DamType == none || DamageNumbers == none ) {
        SendDamageAck(Damage, HitLocation, DamTypeNum);
        return;
    }

    DamageNumbers.DamageMade(Damage, HitLocation, DamTypeNum, Victim, DamType);
}

simulated protected function ClientPlayerDamaged(int Damage, vector HitLocation, byte DamTypeNum)
{
    local ScrnHUD hud;

    hud = ScrnHUD(myHUD);
    if ( hud != none ) {
        if ( hud.ShowDamages > 0 )
            hud.ShowDamage(Damage, Level.TimeSeconds, HitLocation, DamTypeNum);
        else {
            DamageAck = 0;
            ServerAcknowledgeDamages(0); // tell server we don't need damage acks
        }
    }
}

simulated function ClientFlareDamage(KFMonster Victim, byte DamageX4, byte BurnTime)
{
    local ScrnFlareCloud cloud;

    if ( Level.NetMode == NM_DedicatedServer )
        return;
    if ( Victim == none )
        return; // victim is not replicated

    cloud = Spawn(FlareCloudClass, Victim,, Victim.Location, rotator(vect(0,0,1)));
    cloud.SetDamage(DamageX4 * 4);
    cloud.SetLifeSpan(BurnTime);
}

function ServerAcknowledgeDamages(byte WantDamage)
{
    DamageAck = WantDamage;

    if (DamageAck == 1) {
        if ( DamageNumbers == none ) {
            DamageNumbers = spawn(DamageNumbersClass, self);
            DamageNumbers.PC = self;
        }
    }
    else if ( DamageNumbers != none ) {
        DamageNumbers.Destroy();
        DamageNumbers = none;
    }
}

// Set a new recoil amount
// LastRecoilTime changed from timestamp (that does not work properly during the Zed Time) to countdown
simulated function SetRecoil(rotator NewRecoilRotation, float NewRecoilSpeed)
{
    if ( LastRecoilTime <= 0 ) {
        // new recoil rate
        RecoilRotator = NewRecoilRotation / NewRecoilSpeed;
    }
    else {
        // add to the current recoil rate
        RecoilRotator = ((RecoilRotator * RecoilSpeed) + NewRecoilRotation) / NewRecoilSpeed;
    }
    LastRecoilTime = NewRecoilSpeed;
    RecoilSpeed = NewRecoilSpeed;
}

simulated function rotator RecoilHandler(rotator NewRotation, float DeltaTime)
{
    if( LastRecoilTime > 0 ) {
        NewRotation += RecoilRotator * fmin(deltatime, LastRecoilTime);
        LastRecoilTime -= DeltaTime;
    }
    return NewRotation;
}

simulated function ClientMonsterBlamed(class<KFMonster> BlamedMonsterClass)
{
    local ScrnHUD hud;

    hud = ScrnHUD(myHUD);
    if (  hud != none ) {
        hud.BlameCountdown = hud.default.BlameCountdown;
        hud.BlamedMonsterClass = BlamedMonsterClass;
    }
}

exec function ScrnInit()
{
    local LinkedReplicationInfo L;

    // reload ScrnBalance settings
    Mut.InitSettings();

    // reload custom weapon bonuses
    for ( L = Mut.CustomWeaponLink; L != none; L = L.NextReplicationInfo ) {
        ScrnCustomWeaponLink(L).LoadWeaponBonuses();
    }
}

simulated function PlayerTick( float DeltaTime )
{
    local float y, p;

    super.PlayerTick(DeltaTime);

    //log("Player Controller Tick", 'ScrnBalance');
    if ( Viewport(Player) != None ) {
        if ( PendingAchievements.Length > 0 && Level.TimeSeconds >  AchievementDisplayCooldown ) {
            CurrentAchHandler = PendingAchievements[0].AchHandler;
            CurrentAchIndex = PendingAchievements[0].AchIndex;
            PendingAchievements.remove(0, 1);
            DisplayCurrentAchievement();
        }

        if ( Pawn != none && Pawn.Health > 0 ) {
            if ( PrevRot.Yaw != 0 ) {
                y = abs(Rotation.Yaw - PrevRot.Yaw);
                p = abs(Rotation.Yaw - PrevRot.Yaw);
                if ( y<10000 && p<10000 && p+y>2500 /*&& (p*p + y*y) > 4000000*/ ) {
                    if ( IsAimingToZedHead() )
                        ab_warning+=10; // you made inssanely quick mouse movement and pointed exactly into enemy head. What are you, aimbot?..
                    else
                        ab_warning--; // nah, seems like you need to reduce mouse sensitivity...
                }
            }
            PrevRot = Rotation;
        }

        // set typing to true also when console is open
        if ( Player.Console != none ) {
            bIsTyping = Player.Console.bVisible || Player.Console.bTyping || Player.GUIController.bActive;
            if ( Pawn != none && bIsTyping != Pawn.bIsTyping )
                Typing(bIsTyping); // replicate state to server
        }

        if ( KFInterAct != none && PendingSong != "" && PendingSong == KFInterAct.ActiveSong ) {
            // don't bother with this, if player has turned off music
            if ( GetMusicVolume() > 0 ) {
                if ( KFInterAct.ActiveHandel == 0) {
                    // unable to start song - play default one
                    ClientMessage("Unable to play music file: '"$PendingSong$".ogg'. Playing default song instead.", 'Log');
                    PlayDefaultMusic(class'ScrnMusicTrigger');
                }
                else
                    SongPlaying(PendingSong, ActiveMusicSongIndex);
            }
            PendingSong = "";
        }
    }
}

// TraderMenuOpened and TraderMenuClosed execute on client-side only
simulated function TraderMenuOpened()
{
    bShopping = true;
}

simulated function TraderMenuClosed()
{
    if ( Mut.bTSCGame )
        ServerShowPathTo(1); // go to TSC base
    bShopping = false;
}

function SetShowPathToTrader(bool bShouldShowPath)
{
    if ( bShouldShowPath )
        PathDestination = 0; // trader
    else if ( PathDestination == 0)
        PathDestination = 255; // turn off only if we are showing path to trader (PathDestination = 0)
    ServerShowPathTo(PathDestination);
}

exec function TogglePathToTrader()
{
    switch (PathDestination) {
        case 0:
            PathDestination = 1; // TSC base
            if ( Mut.bTSCGame )
                break; // otherwise go to next step
        case 1:
            PathDestination = 255; // hide
            break;
        default:
            PathDestination = 0; // trader
    }
    ServerShowPathTo(PathDestination);
}

function ServerShowPathTo(byte NewDestination)
{
    PathDestination = NewDestination;
    SetTimer(TraderPathInterval, true);
    Timer();
}

// Show the path the trader
function Timer()
{
    if( Role < ROLE_Authority )
    {
        SetTimer(0, false);
    }
    else if ( bWantsTraderPath && PathDestination != 255 )
    {
        UnrealMPGameInfo(Level.Game).ShowPathTo(Self, PathDestination);
    }
    else
    {
        bShowTraderPath = false;
        SetTimer(0, false);
    }
}

event SongPlaying(String Song, int MyIndex)
{
    if ( Song == "" )
        return;

    if ( MyIndex >=0 && MyIndex < MyMusic.length && MyMusic[MyIndex].Song == Song ) {
        if ( MyMusic[MyIndex].Title == "" )
            MyMusic[MyIndex].Title = MyMusic[MyIndex].Song;
        ClientMessage(strPlayingSong
            $ ConsoleColorString(MyMusic[MyIndex].Artist, 192, 1, 192)
            @ ConsoleColorString(MyMusic[MyIndex].Title, 255, 255, 1)
        );
    }
    else {
        for ( MyIndex = 0; MyIndex < MyMusic.length; ++MyIndex ) {
            if ( MyMusic[MyIndex].Song == Song )
                SongPlaying(Song, MyIndex);
        }
    }
}

function UpdateMusicPlaylistIndex()
{
    local int i, prev_pl;

    bMusicPlaylistIndexReady = true;
    for ( i=0; i<MyMusic.length; ++i ) {
        if ( MyMusic[i].PL != prev_pl ) {
            if ( MyMusic[i].PL < prev_pl ) {
                ClientMessage("MyMusic broken! MyMusic must be sorded in (PL,Wave,bTrader) order! Line Number = " $i, 'Log');
                MusicPlaylistIndex.Length = 0;
                return;
            }
            prev_pl = MyMusic[i].PL;
            MusicPlaylistIndex[prev_pl] = i;
        }
    }
}

/**
 *  Gets song name from MyMusic according to playlist (PL) and wave numbers.
 *  Function doesn't check if music file exists.
 *
 *  @param PL       Playlist number as defined in MyMusic.PL. Starting with 1. PL=0 is reserved for default music.
 *                  Calling GetMySong with PL = 0 always returns empty string.
 *  @param Wave     Player-friendly wave number, i.e. 1 - Wave 1, 11 - Boss wave etc.
 *                  Calling GetMySong with Wave=0 returns default song for this playlist
 *  @param bTrader  Are we looking for calm song for trader time (bTrader=True) or battle song (false)?
 *  @return         Record index in MyMusic. -1 if not found
 */
function int GetMySongIndex(byte PL, byte Wave, bool bTrader)
{
    local int i, start, end;
    local bool bFound;

    if ( !bMusicPlaylistIndexReady )
        UpdateMusicPlaylistIndex();

    if ( PL == 0 )
        return -1;

    if ( PL >= MusicPlaylistIndex.Length ) {
        if ( ActiveMusicPlaylist == PL )
            ActiveMusicPlaylist = 0;
        ClientMessage("Music Playlist #"$PL $" is not defined", 'Log');
        return -1;
    }

    start = MusicPlaylistIndex[PL];
    if ( start >= MyMusic.Length ) {
        ClientMessage("Music Playlist #"$PL $" has no songs or MyMusic is not sorted", 'Log');
        return -1;
    }
    if ( (PL+1) == MusicPlaylistIndex.Length )
        end = MyMusic.length;
    else
        end = MusicPlaylistIndex[PL+1];

    for ( i = start; i < end; ++i ) {
        if ( bFound ) {
            if ( MyMusic[i].Wave != Wave || MyMusic[i].bTrader != bTrader ) {
                end = i;
                break;
            }
        }
        else if ( MyMusic[i].Wave == Wave && MyMusic[i].bTrader == bTrader ) {
            bFound = true;
            start = i;
        }
    }
    if ( bFound ) {
        if ( start + 1 == end )
            return start;
        else
            return start + Rand(end-start);
    }
    else if ( Wave >  0)
        return GetMySongIndex(PL, 0, bTrader); // no songs defined for given wave. return default

    return -1;
}

function int GetMyActiveSongIndex()
{
    local KFGameReplicationInfo KFGRI;
    local byte w;

    KFGRI = KFGameReplicationInfo(Level.GRI);
    if ( KFGRI == none )
        return -1; // wtf?
    if ( KF_StoryGRI(KFGRI) != none ) {
        // story mode
        return -1; // story music must be set explicitly by L.D.
    }

    w = KFGRI.WaveNumber;
    if ( KFGRI.bWaveInProgress ) {
        if ( w == KFGRI.FinalWave && TSCGameReplicationInfo(KFGRI) == none )
            w = 10; // boss battle song
    }
    return GetMySongIndex(ActiveMusicPlaylist, w+1, !KFGRI.bWaveInProgress);
}

function PlayDefaultMusic(class<KFMusicTrigger> M)
{
    local string sng;

    if ( KFInterAct == none )
        return;

    sng = GetSongFromMusicTrigger(M);
    if ( sng != "" )
        KFInterAct.SetSong(sng, M.default.FadeInTime, M.default.FadeOutTime);
}

function string GetSongFromMusicTrigger(class<KFMusicTrigger> M)
{
    local KFGameReplicationInfo KFGRI;
    local string sng;
    local int w;

    KFGRI = KFGameReplicationInfo(Level.GRI);
    if ( KFGRI == none )
        return sng; // wtf?
    if ( KF_StoryGRI(KFGRI) != none )
        return sng; // story music must be set explicitly by L.D.

    w = KFGRI.WaveNumber;
    if ( KFGRI.bWaveInProgress ) {
        if ( w == KFGRI.FinalWave && M.default.WaveBasedSongs.length > 10 && TSCGameReplicationInfo(KFGRI) == none )
            sng = M.default.WaveBasedSongs[10].CombatSong; // boss battle song
        else if ( w < M.default.WaveBasedSongs.length )
            sng = M.default.WaveBasedSongs[w].CombatSong;
        else
            sng = M.default.CombatSong;
    }
    else {
        if ( KFGRI.TimeToNextWave > 10 )
            w++; // KFGRI.WaveNumber is updated only at the end of the trader time
        if ( w < M.default.WaveBasedSongs.length )
            sng = M.default.WaveBasedSongs[w].CalmSong;
        else
            sng = M.default.Song;
    }
    return sng;
}

function int GetActiveMusicSongIndex()
{
    return ActiveMusicSongIndex;
}

function NetPlayMusic( string Song, float FadeInTime, float FadeOutTime )
{
    if ( ActiveMusicPlaylist > 0 ) {
        ActiveMusicSongIndex = GetMyActiveSongIndex();
        if ( ActiveMusicSongIndex != -1 )
            Song = MyMusic[ActiveMusicSongIndex].Song;
    }
    else
        ActiveMusicSongIndex = -1;

    PendingSong = Song;
    super.NetPlayMusic(Song, FadeInTime, FadeOutTime);
}

exec function PlayMyMusic(int PL)
{
    local int i;

    if ( !bMusicPlaylistIndexReady )
        UpdateMusicPlaylistIndex();

    if ( MusicPlaylistIndex.length <= 1 ) {
        ConsoleMessage("No user-defined music available", 0, 255, 1, 1);
        return;
    }

    if ( PL >= MusicPlaylistIndex.length ) {
        ConsoleMessage("Wrong playlist number!", 0, 255, 1, 1);
        PL = 0;
    }

    if ( PL == 0) {
        ConsoleMessage("Available music playlists:");
        ConsoleMessage("---------------------------------------------");
        for ( i=1; i<MusicPlaylistIndex.length; ++i ) {
            if ( ActiveMusicPlaylist == i )
                ConsoleMessage(i @ MusicPlaylistNames[i], 0, 1, 255, 1);
            else
                ConsoleMessage(i @ MusicPlaylistNames[i]);
        }
        ConsoleMessage("---------------------------------------------");
        if ( ActiveMusicSongIndex != -1 )
             ConsoleMessage(strPlayingSong
                $ ConsoleColorString(MyMusic[ActiveMusicSongIndex].Artist, 192, 1, 192)
                @ ConsoleColorString(MyMusic[ActiveMusicSongIndex].Title, 255, 255, 1)
            );
        return;
    }

    ActiveMusicPlaylist = PL;
    NetPlayMusic("ThisWillBeReplacedWithDefaultWaveTrack", 1, 1);
    ClientMessage(ConsoleColorString(MusicPlaylistNames[PL], 1, 192, 1)
        $ ConsoleColorString(" activated", 192, 192, 192));
    SaveConfig();
}

exec function StopMyMusic(int PL)
{
    if ( ActiveMusicPlaylist > 0 ) {
        ActiveMusicPlaylist = 0;
        ClientMessage("User-defined music disabled. Map-specific music will be restored next wave.");
        SaveConfig();
    }
}

function float GetMusicVolume()
{
    return float(ConsoleCommand("get ini:Engine.Engine.AudioDevice MusicVolume"));
}

exec function MusicVolume(coerce string vol)
{
    if ( vol == "" )
        ClientMessage("Music Volume = " $ ConsoleCommand("get ini:Engine.Engine.AudioDevice MusicVolume"));
    else {
        ConsoleCommand("set ini:Engine.Engine.AudioDevice MusicVolume" @ vol);
        ClientMessage("Music Volume set to " $ ConsoleCommand("get ini:Engine.Engine.AudioDevice MusicVolume"));
    }
}

exec function SoundVolume(coerce string vol)
{
    if ( vol == "" )
        ClientMessage("Sound Volume = " $ ConsoleCommand("get ini:Engine.Engine.AudioDevice SoundVolume"));
    else {
        ConsoleCommand("set ini:Engine.Engine.AudioDevice SoundVolume" @ vol);
        ClientMessage("Sound Volume set to " $ ConsoleCommand("get ini:Engine.Engine.AudioDevice SoundVolume"));
    }
}


function bool IsAimingToZedHead()
{
    local Vector vNull, StartTrace, HeadLoc, LookDir, HeadDir;
    local KFMonster HitMonster;
    local float cosine;

    if ( Pawn == none )
        return false;

    StartTrace = Pawn.Location + Pawn.EyePosition();  // A
    LookDir = Normal(Vector(Rotation)); // B-A

    foreach CollidingActors(class'KFMonster', HitMonster, 2500, StartTrace) {
        HeadLoc = HitMonster.GetBoneCoords('head').Origin;
        if ( HeadLoc == vNull )
            continue; // no head

        if ( !FastTrace(HeadLoc, StartTrace) )
            continue; // head isn't visible

        // I should have better learned geometry in school. It'd really helped :)
        // LookDir - direction where player is lookin
        // HeadDir - direction to the zed's head (HeadLoc)
        // We need to get a distance between HeadLoc and our LookDir line,
        // i.e. perpenducular line from HeadLoc to LookDir line.
        // We get right-angled triangle, where (HeadLoc-StartTrace) is Hypotenuse,
        // LookDir line - Adjacent side and perpendicular line - opposite side.
        // Opposite = Hypotenuse * sin, where sin = 1 - cos,
        // and cos = dot product of two normalized direction vectors.
        HeadDir = normal(HeadLoc - StartTrace);
        // cos=1.0 - target in front of us
        // cos=0.0 - target is at side (left or right)
        // cos=0.5 - target is 45 degrees from our looking direction
        cosine = LookDir dot HeadDir;
        if ( cosine > 0.9 && VSizeSquared(HeadLoc - StartTrace) * (1.0-cosine) < 25 )
            return true;
    }
    return false;
}



simulated function DisplayCurrentAchievement()
{
    if ( Viewport(Player) == None )
        return;
    //log("DisplayCurrentAchievement:" @CurrentAchievement.ID @ CurrentAchievement.CurrentProgress$"/"$ CurrentAchievement.MaxProgress ,'ScrnBalance');
    if ( CurrentAchHandler != none ) {
        bWasAchUnlockedJustNow = CurrentAchHandler.AchDefs[CurrentAchIndex].bUnlockedJustNow;
        if ( bWasAchUnlockedJustNow ) {
            ClientPlaySound(Sound'KF_InterfaceSnd.Perks.PerkAchieved',true,2.f,SLOT_Talk);
            ClientPlaySound(Sound'KF_InterfaceSnd.Perks.PerkAchieved',true,2.f,SLOT_Interface);
        }
        CurrentAchHandler.AchDefs[CurrentAchIndex].bUnlockedJustNow = false;
        AchievementDisplayCooldown = Level.TimeSeconds + default.AchievementDisplayCooldown;
        ReceiveLocalizedMessage(Class'ScrnAchievementEarnedMsg',CurrentAchIndex,self.PlayerReplicationInfo,,CurrentAchHandler);
    }
}


//inform client that he earned an achievement
simulated function DisplayAchievementStatus(ScrnAchievements AchHandler, int AchIndex)
{
    if ( Viewport(Player) == None || AchHandler == none || !AchHandler.IsAchievementIndexValid(AchIndex) )
        return;
    if ( AchHandler.AchDefs[AchIndex].CurrentProgress > 0 ) {
        if ( AchHandler.AchDefs[AchIndex].bUnlockedJustNow )
            ConsoleMessage(Class'ScrnAchievementEarnedMsg'.default.EarnedString $ ": "
                    $ AchHandler.AchDefs[AchIndex].DisplayName, 0, 1, 200, 1);

        if ( PendingAchievements.Length == 0 && (Level.TimeSeconds > AchievementDisplayCooldown
                || (!bWasAchUnlockedJustNow && (AchHandler.AchDefs[AchIndex].bUnlockedJustNow
                    || CurrentAchHandler == none
                    || AchHandler.AchDefs[AchIndex].MaxProgress < CurrentAchHandler.AchDefs[CurrentAchIndex].MaxProgress))) )
        {
            // no need to use a queue for a single achievement
            CurrentAchHandler = AchHandler;
            CurrentAchIndex = AchIndex;
            DisplayCurrentAchievement();
        }
        else if ( AchHandler.AchDefs[AchIndex].bUnlockedJustNow ){
            //don't bother player with status updates, when other achievements have been really earned
            PendingAchievements.insert(PendingAchievements.Length, 1);
            PendingAchievements[PendingAchievements.Length-1].AchHandler = AchHandler;
            PendingAchievements[PendingAchievements.Length-1].AchIndex = AchIndex;
        }
    }
}


static final function string ConsoleColorString(string s, byte R, byte G, byte B)
{
    return chr(27)$chr(max(R,1))$chr(max(G,1))$chr(max(B,1))$s;
}

simulated function ConsoleMessage(string Msg, optional float MsgLife, optional byte R, optional byte G, optional byte B)
{
    if ( Player != none && Player.Console != none ) {
        if ( R != 0 || G != 0 || B != 0 )
            Msg = ConsoleColorString(Msg, R, G, B);
        Player.Console.Message(Msg, MsgLife);
    }
}

simulated function string MyColoredName()
{
    return Mut.ColoredPlayerName(PlayerReplicationInfo);
}

event ClientMessage( coerce string S, optional Name Type )
{
    if ( Level.NetMode == NM_DedicatedServer || GameReplicationInfo == None )
        return;

    if ( Type == 'Log' ) {
        log(class'ScrnFunctions'.static.StripColorTags(S), 'ScrnBalance');
        Type = '';
    }

    if ( Mut != none )
        super.ClientMessage(class'ScrnFunctions'.static.ParseColorTags(S, PlayerReplicationInfo), Type);
    else
        super.ClientMessage(S, Type);
}

function LongMessage(string S, optional int MaxLen, optional string Divider)
{
    class'ScrnFunctions'.static.LongMessage(self, S, MaxLen, Divider);
}

event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type  )
{
    local string c;

    // Wait for player to be up to date with replication when joining a server, before stacking up messages
    if ( Level.NetMode == NM_DedicatedServer || GameReplicationInfo == None )
        return;

    if( AllowTextToSpeech(PRI, Type) )
        TextToSpeech( S, TextToSpeechVoiceVolume );
    if ( Type == 'TeamSayQuiet' )
        Type = 'TeamSay';

    if ( myHUD != None )
        myHUD.Message( PRI, c$S, Type );

    if ( Player != None && Player.Console != None ) {
        if ( PRI!=None ) {
            if ( PRI.Team!=None && GameReplicationInfo.bTeamGame ) {
                if ( PRI.Team.TeamIndex == 0 )
                    c = chr(27)$chr(200)$chr(1)$chr(1);
                else if ( PRI.Team.TeamIndex == 1 )
                    c = chr(27)$chr(75)$chr(139)$chr(198);
            }
            S = Mut.ColoredPlayerName(PRI) $ c $ ": " $ class'ScrnFunctions'.static.ParseColorTags(S, PRI);
        }
        Player.Console.Chat( c$s, 6.0, PRI );
    }
}

simulated function ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
    if ( Message == class'KFVetEarnedMessageSR' ||  Message == class'ScrnPromotedMessage'
            || (Message == class'KFVetEarnedMessagePL' && RelatedPRI_1 == PlayerReplicationInfo) ) {
        Message = class'ScrnPromotedMessage';
    }
    else if ( Message == class'TSCMessages' ) {
        switch (Switch) {
            case 300:     // trying to shop in enemy trader
                ClientCloseMenu(true, true);
                break;
            case 311:   // loosing base means wipe
                if ( ScrnHUD(myHUD) != none )
                    ScrnHUD(myHUD).CriticalOverlayTimer = Level.TimeSeconds + 4.0;
                break;
        }
    }
    super.ReceiveLocalizedMessage(Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

function SendVoiceMessage(PlayerReplicationInfo Sender,
        PlayerReplicationInfo Recipient,
        name messagetype,
        byte messageID,
        name broadcasttype,
        optional Pawn soundSender,
        optional vector senderLocation)
{
    local Controller C;
    local KFPlayerController PC;

    if (Pawn == none || Pawn.Health <= 0)
        return;

    if (!AllowVoiceMessage(MessageType))
        return;

    if (MessageType == 'SUPPORT' && messageID == 0) {
        if (Pawn.Health >= 100)
            return;  // you don't need a medic, buddy
        // replicate player health ASAP
        Sender.Timer();
        Sender.NetUpdateTime = Level.TimeSeconds - 1.0;
        // encode player health into message ID
        MessageType = 'MEDIC';
        messageID = Pawn.Health;
    }

    for (C = Level.ControllerList; C != none; C = C.NextController) {
        PC = KFPlayerController(C);
        if (PC == none)
            continue;

        if (Level.Game.bTeamGame && !SameTeamAs(PC))
            continue;

        PC.ClientLocationalVoiceMessage(Sender, Recipient, messagetype, messageID, soundSender, senderLocation);
    }
}

function ClientLocationalVoiceMessage(PlayerReplicationInfo Sender,
                                      PlayerReplicationInfo Recipient,
                                      name MessageType, byte MessageID,
                                      optional Pawn SenderPawn, optional vector SenderLocation)
{
    local VoicePack Voice;
    local KFVoicePack KFVoice;
    local ShopVolume Shop;
    local name MsgTag;
    local string Msg, Msg2;

    if (Sender == none || Sender.VoiceType == none || Player.Console == none || Level.NetMode == NM_DedicatedServer)
        return;

    MsgTag = 'Voice';
    Voice = Spawn(Sender.VoiceType, self);
    KFVoice = KFVoicePack(Voice);

    if (KFVoice == none) {
        // should not happen
        Voice.ClientInitialize(Sender, Recipient, MessageType, MessageID);
        return;
    }

    if (MessageType == 'TRADER') {
        MsgTag = 'Trader';
        if ( Pawn != none && MessageID >= 4 ) {
            foreach Pawn.TouchingActors(Class'ShopVolume', Shop) {
                SenderLocation = Shop.MyTrader.Location;
                // Only play the 30 Seconds remaining messages come across as Locational Speech if we're in the Shop
                if ( MessageID == 4 )
                    return;

                if ( MessageID == 5 )
                    MessageID = 555;
                break;
            }
        }

        // Only play the 10 Seconds remaining message if we are in the Shop
        // and only play the 30 seconds remaning message if we haven't been to the Shop
        if (MessageID == 5 || (MessageID == 4 && bHasHeardTraderWelcomeMessage))
            return;

        if ( MessageID == 555 ) {
            MessageID = 5;
        }
        else if ( MessageID == 7 ) {
            // Store the fact that we've heard the Trader's Welcome message on the client
            bHasHeardTraderWelcomeMessage = true;
        }
        else if ( MessageID == 6 ) {
            // If we're hearing the Shop's Closed Message, reset the Trader's Welcome message flag
            bHasHeardTraderWelcomeMessage = false;
        }

        if ( MessageID > 6 /*&& bBuyMenuIsOpen*/ ) {
            // TODO: Show KFVoicePack(Voice).GetClientParsedMessage() in the Buy Menu
            return;
        }
    }
    else if (MessageType == 'MEDIC') {
        // decode player health and switch back to v11
        Msg2 = " (" $ MessageID $ "%)";
        MessageType = 'SUPPORT';
        MessageID = 0;
    }

    KFVoice.ClientInitializeLocational(Sender, Recipient, MessageType, MessageID, SenderPawn, SenderLocation);
    Msg = KFVoice.GetClientParsedMessage() $ Msg2;
    if (Msg == "")
        return;
    TeamMessage(Sender, Msg, MsgTag);
}

function ResetWaveStats()
{
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);

    bCowboyForWave = true;
    BeggingForMoney = 0;
    bShoppedThisWave = false;
    bHadArmor = bHadArmor || (KFPRI != none && KFPRI.ClientVeteranSkill != none
        && KFPRI.ClientVeteranSkill.static.ReduceDamage(KFPRI, KFPawn(Pawn), none, 100, none) < 100);

    if ( ScrnPawn != none )
        ScrnPawn.ApplyWeaponStats(Pawn.Weapon);
}

exec function LogAch()
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i, c;

    L = class'ScrnClientPerkRepLink'.static.FindMe(self);

    log("#;GROUP;ID;TITLE;DESCRIPTION", 'Achievement');
    log("============================", 'Achievement');
    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            //log(A.class, 'Package');
            for ( i = 0; i < A.AchDefs.length; ++i ) {
                log(string(++c)
                    $";"$ A.AchDefs[i].Group
                    $";"$ A.AchDefs[i].ID
                    $";"$ A.AchDefs[i].DisplayName
                    $";"$ A.AchDefs[i].Description
                    , 'Achievement');
            }
        }
    }
    ConsoleMessage("Achievement list has been printed to the log file.", 0, 1, 200, 1);
}


exec function AchReset(optional int password)
{
    if ( class'ScrnAchCtrl'.static.IsAchievementUnlocked(class'ScrnClientPerkRepLink'.static.FindMe(self), 'AchReset') ) {
        if ( AchResetPassword == 0 ) {
            AchResetPassword = 10000 + rand(90000);
            ConsoleMessage("You already have 'AchReset' achievement!", 0, 200, 100, 1);
            ConsoleMessage("If sure you want to do this again, then enter the following command:", 0, 200, 100, 1);
            ConsoleMessage("AchReset " $ AchResetPassword, 0, 200, 200, 1);
            return;
        }
        else if ( AchResetPassword != password ) {
            ConsoleMessage("Wrong reset password!", 0, 200, 100, 1);
            return;
        }
    }
    SrvAchReset();
}

function SrvAchReset()
{
    local ClientPerkRepLink L;
    local array<name> GroupNames;
    local array<string> GroupCaptions;
    local int i;

    L = Class'ScrnClientPerkRepLink'.Static.FindMe(self);
    class'ScrnAchCtrl'.static.RetrieveGroups(L, GroupNames, GroupCaptions);
    for ( i=0; i<GroupNames.length; ++i ) {
        if ( GroupNames[i] != 'MAP' )
            class'ScrnAchCtrl'.static.ResetAchievements(L, GroupNames[i]);
    }
    class'ScrnAchCtrl'.static.ProgressAchievementByID(L, 'AchReset', 1);
}

exec function ResetMyAchievements(name group)
{
    class'ScrnAchCtrl'.static.ResetAchievements(Class'ScrnClientPerkRepLink'.Static.FindMe(self), group);
}

exec function ResetMapAch(string MapName)
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;
    local ScrnMapAchievements A;
    local int i, j;

    L = Class'ScrnClientPerkRepLink'.Static.FindMe(self);
    if ( MapName == "" )
        MapName = Mut.KF.GetCurrentMapName(Level);

    if ( L == none || MapName == "" )
        return;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnMapAchievements(S);
        if( A != none ) {
            for ( i = 0; i < A.AchDefs.length; i += 4 ) {
                if ( String(A.AchDefs[i].ID) ~= MapName ) {
                    for ( j=0; j < 4; ++j ) {
                        A.AchDefs[i+j].bUnlockedJustNow = false;
                        A.AchDefs[i+j].CurrentProgress = 0;
                    }
                    ConsoleMessage("Map achievements locked");
                    return;
                }
            }
        }
    }
}

function bool CheckMutateProtection()
{
    if ( Mut.IsAdmin(self) || Mut.bTestMap )
        return true;

    if ( Level.TimeSeconds > LastMutateTime ) {
        MutateCounter = 1;
        LastMutateTime = Level.TimeSeconds + 10;
    }
    else if ( ++MutateCounter >= 10 ) {
        if ( MutateCounter == 10 ) {
            LastMutateTime = Level.TimeSeconds + 10;
        }
        if ( Level.NetMode != NM_DedicatedServer && Viewport(Player) != None ) {
            ClientMessage(strMutateProtection);
        }
        return false;
    }
    return true;
}

exec function Mutate(string MutateString)
{
    if ( CheckMutateProtection() )
        ServerMutate(MutateString);
}

function ServerMutate(string MutateString)
{
    if( Level.NetMode == NM_Client || !CheckMutateProtection() )
        return;
    Level.Game.BaseMutator.Mutate(MutateString, Self);
}

exec function MVote(string VoteString)
{
    ServerMutate("VOTE " $ VoteString);
}

exec function MVB(string Params)
{
    ServerMutate("VOTE BLAME " $ Params);
}

exec function MVM(string Params)
{
    ServerMutate("VOTE MAP " $ Params);
}

exec function Say(string Msg)
{
    // Msg = Level.Game.StripColor(Msg);

    if (Msg ~= "!yes")
        ServerMutate("VOTE YES");
    else if (Msg ~= "!no")
        ServerMutate("VOTE NO");
    else
        super.Say(Msg);
}

exec function TeamSay( string Msg )
{
    //Msg = Level.Game.StripColor(Msg);

    if (Msg ~= "!yes")
        ServerMutate("VOTE YES");
    else if (Msg ~= "!no")
        ServerMutate("VOTE NO");
    else
        super.TeamSay(Msg);
}

function ServerSpeech( name Type, int Index, string Callsign )
{
    if ( bSpeechVote && Type == 'ACK' ) {
        if ( index == 0 )
            ServerMutate("VOTE TRYYES");
        else if ( index == 1 )
            ServerMutate("VOTE TRYNO");
    }
    if ( Type == 'SUPPORT' && Index == 2 ) {
        BeggingForMoney++;
    }

    super.ServerSpeech(Type, Index, Callsign);
}



exec function AmIMedic()
{
    if ( ScrnPawn != none )
        ConsoleMessage(String(ScrnPawn.IsMedic()));
}

// overrided to call vote for pause in unable to pause directly
function bool SetPause( BOOL bPause )
{
    bFire = 0;
    bAltFire = 0;
    if ( !Level.Game.SetPause(bPause, self) ) {
        ServerMutate("VOTE PAUSE 120");
        return false;
    }
    return true;
}

function BecomeSpectator()
{
    local bool bWasOnlySpectator;

    bWasOnlySpectator = PlayerReplicationInfo.bOnlySpectator;
    super.BecomeSpectator();

    if (Role < ROLE_Authority)
        return;

    if ( PlayerReplicationInfo.bOnlySpectator && !bWasOnlySpectator )
        Mut.GameRules.PlayerLeaving(self);

    if ( Mut.bDynamicLevelCap && Mut.KF.bTradingDoorsOpen )
        Mut.DynamicLevelCap();
}

function BecomeActivePlayer()
{
    local bool bWasOnlySpectator;

    bWasOnlySpectator = PlayerReplicationInfo.bOnlySpectator;
    super.BecomeActivePlayer();


    if (Role < ROLE_Authority) {
        if ( ScrnHUD(MyHUD) != none ) {
            ScrnHUD(MyHUD).DisableHudHacks();
        }
        return;
    }

    if ( !PlayerReplicationInfo.bOnlySpectator ) {
        if ( Mut.KF.bTradingDoorsOpen ) {
            if ( Mut.bDynamicLevelCap )
                Mut.DynamicLevelCap();
        }
        StartCash = PlayerReplicationInfo.Score;
        if ( bWasOnlySpectator )
            Mut.GameRules.PlayerEntering(self);
    }
}

/*
 * Executes everry time when Pawn property is changes.
 * May also execute when Pawn is reset to the same value (i.e. value does not change)
 */
function OnPawnChanged()
{
    if ( ScrnPawn != none && ScrnPawn != Pawn ) {
        // unlink the old pawn
        ScrnPawn.ScrnPC = none;
    }
    ScrnPawn = ScrnHumanPawn(Pawn);
    if ( ScrnPawn == none && Pawn != none ) {
        if ( Vehicle(Pawn) != none ) {
            ScrnPawn = ScrnHumanPawn(Vehicle(Pawn).Driver);
        }
        if ( ScrnPawn == none ) {
            warn("ScrnPlayerController possessed a non-ScrnHumanPawn: " $ Pawn);
        }
    }
    if ( ScrnPawn != none ) {
        ScrnPawn.ScrnPC = self;
        ScrnPawn.KFPC = self;
    }
}

function Possess(Pawn aPawn)
{
    local Rotator R, R2Door;
    local KFTraderDoor door, BestDoor;
    local ShopVolume shop;
    local bool bTurnAroundValid;

    //ClientMessage("Possess("$aPawn$"). Current Pawn="$Pawn);
    if ( Role == ROLE_Authority && Mut != none ) {
        if ( bHadPawn )
            StartCash = max(StartCash, Mut.KF.MinRespawnCash);
        else
            StartCash = max(StartCash, Mut.KF.StartingCash);

        if ( Mut.ScrnGT != none && Mut.ScrnGT.ScrnGameLength != none && Mut.ScrnGT.ScrnGameLength.Wave.bStartAtTrader )
        {
            R = aPawn.Rotation;
            // spawnned at the trader on a trader teleporter.
            // Releporters usually are facing away from the trader, so turn 180
            R.yaw += 32768;
            R = Normalize(R);

            shop = Mut.ScrnGT.TeamShop(PlayerReplicationInfo.Team.TeamIndex);
            foreach aPawn.VisibleCollidingActors(class'KFTraderDoor', door, 1000, aPawn.Location) {
                if ( door.Tag == shop.Event ) {
                    if ( BestDoor == none )
                        BestDoor = door;
                    R2Door = R;
                    R2Door.yaw = rotator(door.Location - aPawn.Location).yaw;
                    if ( abs(Normalize(R2Door - R).yaw) < 4096 ) {
                        // rotation to the door is almost the same as rotation by 180.
                        // In that case use turnaround as it looks better
                        bTurnAroundValid = true;
                    }
                    break;
                }
            }
            if ( !bTurnAroundValid && BestDoor != none ) {
                // turnaround doesn't face any of trader doors. Rotate to door directly
                R.yaw = rotator(door.Location - aPawn.Location).yaw;
            }
            aPawn.SetRotation(R);
        }
    }

    super.Possess(aPawn);
    OnPawnChanged();

    // show path to trader if respawned during the trader time
    if ( Role == ROLE_Authority && Pawn != none && Mut != none && Mut.KF.bTradingDoorsOpen )
        SetShowPathToTrader(true);

    bHadPawn = bHadPawn || Pawn != none;
}

function UnPossess()
{
    super.UnPossess();
    OnPawnChanged();
}

function AcknowledgePossession(Pawn P)
{
    super.AcknowledgePossession(P);
    OnPawnChanged();
}

function PendingStasis()
{
    super.PendingStasis();
    OnPawnChanged();
}

function GivePawn(Pawn NewPawn)
{
    super.GivePawn(NewPawn);
    OnPawnChanged();
}

simulated event Destroyed()
{
    bDestroying = true;

    if ( ScrnPawn != none )
        ScrnPawn.HealthBeforeDeath = Pawn.Health;

    if ( DamageNumbers != none ) {
        DamageNumbers.Destroy();
    }


    if ( Role == ROLE_Authority ) {
        if ( Mut != none &&  PlayerReplicationInfo != none ) {
            if ( Mut.bLeaveCashOnDisconnect && PlayerReplicationInfo.Team != none
                && PlayerReplicationInfo.Score > StartCash )
            {
                PlayerReplicationInfo.Team.Score += PlayerReplicationInfo.Score - StartCash;
                PlayerReplicationInfo.Score = StartCash; // just in case
            }
            if ( Mut.GameRules != none )
                Mut.GameRules.PlayerLeaving(self);
        }
    }

    super.Destroyed();

    if ( Role == ROLE_Authority ) {
        if ( Mut != none && Mut.bDynamicLevelCap && Mut.KF.bTradingDoorsOpen )
            Mut.DynamicLevelCap();
    }
}

simulated function ClientEnterZedTime()
{
    super.ClientEnterZedTime();
    bZEDTimeActive = true;
}

simulated function ClientExitZedTime()
{
    super.ClientExitZedTime();
    bZEDTimeActive = false;
}

function EnterZedTime()
{
    bZEDTimeActive = true;
    ClientEnterZedTime();
}

function ExitZedTime()
{
    bZEDTimeActive = false;
    ClientExitZedTime();
}

function bool AllowVoiceMessage(name MessageType)
{
    local float TimeSinceLastMsg;

    if ( Level.NetMode == NM_Standalone || (PlayerReplicationInfo != none && PlayerReplicationInfo.bAdmin) )
        return true;

    TimeSinceLastMsg = Level.TimeSeconds - OldMessageTime;

    if ( TimeSinceLastMsg < 3 )
    {
        if ( (MessageType == 'TAUNT') || (MessageType == 'AUTOTAUNT') )
            return false;
        if ( TimeSinceLastMsg < 1 )
            return false;
    }

    // zed time screws up voice messages
    if ( !bZEDTimeActive && MessageType != 'TRADER' && MessageType != 'AUTO' ) {
        OldMessageTime = Level.TimeSeconds;
        if ( TimeSinceLastMsg < 10 ) {
            if ( MaxVoiceMsgIn10s > 0 )
                MaxVoiceMsgIn10s--;
            else {
                ClientMessage("Keep quiet for " $ ceil(10-TimeSinceLastMsg) $"s");
                return false;
            }
        }
        else
            MaxVoiceMsgIn10s = default.MaxVoiceMsgIn10s;
    }
    return true;
}

exec function DropAllWeapons()
{
    ServerDropAllWeapons();
}

function ServerDropAllWeapons()
{
    class'ScrnHumanPawn'.static.DropAllWeapons(Pawn);
}

exec function LockWeapons()
{
    if ( Mut.bAllowWeaponLock ) {
        bWeaponsLocked = true;
        ServerLockWeapons(bWeaponsLocked);
        ClientMessage(ConsoleColorString(strLocked, 192, 1, 1));
    }
    else
        ClientMessage(strLockDisabled);
}

exec function UnlockWeapons()
{
    if ( Mut.bAllowWeaponLock ) {
        bWeaponsLocked = false;
        ServerLockWeapons(bWeaponsLocked);
        ClientMessage(ConsoleColorString(strUnlocked, 1, 192, 1));
    }
    else
        ClientMessage(strLockDisabled);
}

exec function ToggleWeaponLock()
{
    if ( bWeaponsLocked )
        UnlockWeapons();
    else
        LockWeapons();
}

function ServerLockWeapons(bool bLock)
{
    bWeaponsLocked = Mut.bAllowWeaponLock && bLock;
}

//handles changing weapon's inventorygroup
exec function WeaponSlot(optional byte Slot)
{
    local KFWeapon weap;

    if ( Pawn == none )
        return;
    weap = KFWeapon(Pawn.Weapon);
    if ( weap == none )
        return;

    if ( Slot == 0 ) {
        ClientMessage(weap.ItemName $ " is in slot " $ weap.InventoryGroup);
    }
    else {
        weap.InventoryGroup = Slot;
        ClientMessage(weap.ItemName $ " moved to slot " $ weap.InventoryGroup);
    }
}

exec function GunSlot(optional byte Slot)
{
    WeaponSlot(Slot);
}

exec function Ready()
{
    if ( PlayerReplicationInfo.bOnlySpectator ) {
        BecomeActivePlayer();
        return;
    }

    if ( PlayerReplicationInfo.Team == none )
        return;

    if ( Level.NetMode == NM_Standalone || !PlayerReplicationInfo.bReadyToPlay ) {
        SendSelectedVeterancyToServer(true);

        //Set Ready
        ServerRestartPlayer();
        PlayerReplicationInfo.bReadyToPlay = True;
        if ( Level.GRI.bMatchHasBegun )
            ClientCloseMenu(true, false);
    }
}

exec function Spectate()
{
    if ( PlayerReplicationInfo.bOnlySpectator ) {
        ConsoleMessage(strAlreadySpectating);
        return;
    }
    ClientCloseMenu(true, false);
    BecomeSpectator();
}

exec function Unready()
{
    if ( Level.GRI.bMatchHasBegun )
        return;

    ServerUnreadyPlayer();
    PlayerReplicationInfo.bReadyToPlay = False;
}

exec function ShowMenu()
{
    if ( Level.GRI.bMatchHasBegun || PlayerReplicationInfo.bOnlySpectator )
        super.ShowMenu();
    else
        ShowLobbyMenu();
}

function ShowLobbyMenu()
{
    StopForceFeedback();  // jdf - no way to pause feedback

    bPendingLobbyDisplay = false;

    // Open menu
    if (  TSCGameReplicationInfo(Level.GRI) != none && !TSCGameReplicationInfo(Level.GRI).bSingleTeamGame )
        ClientOpenMenu(TSCLobbyMenuClassString);
    else
        ClientOpenMenu(LobbyMenuClassString);
}


function LoadDualWieldables()
{
    local ScrnClientPerkRepLink L;
    local class<KFWeaponPickup> WP;
    local class<KFWeapon> W;
    local int i;

    L = class'ScrnClientPerkRepLink'.static.FindMe(self);
    if( L==None || L.ShopInventory.Length == 0 )
        return; // Hmmmm?


    for ( i=0; i<L.ShopInventory.Length; ++i ) {
        WP = class<KFWeaponPickup>(L.ShopInventory[i].PC);
        if ( WP == none )
            continue;
        W = class<KFWeapon>(WP.default.InventoryType);
        if ( W != none && W.Default.DemoReplacement != none )
            AddDualWieldable(class<KFWeapon>(W.Default.DemoReplacement), W);
    }

    bDualWieldablesLoaded = L.PendingWeapons == 0;
}

final function AddDualWieldable(class<KFWeapon> SingleWeapon, class<KFWeapon> DualWeapon)
{
    local int i;

    if ( SingleWeapon == none || DualWeapon == none )
        return;

    for ( i=0; i<DualWieldables.Length; ++i ) {
        if ( DualWieldables[i].Single == SingleWeapon || DualWieldables[i].Dual == DualWeapon)
            break;
    }
    if ( i == DualWieldables.Length )
        DualWieldables.insert(i, 1);

    DualWieldables[i].Single = SingleWeapon;
    DualWieldables[i].Dual = DualWeapon;
}

function bool IsSinglePistol(class<KFWeapon> Weapon)
{
    local int i;

    if ( !bDualWieldablesLoaded )
        LoadDualWieldables();

    if ( Weapon == none )
        return false;

    for ( i=0; i<DualWieldables.Length; ++i ) {
        if ( DualWieldables[i].Single == Weapon )
            return true;
    }

    return false;
}

function bool AreDualPistols(class<KFWeapon> Weapon)
{
    local int i;

    if ( !bDualWieldablesLoaded )
        LoadDualWieldables();

    if ( Weapon == none )
        return false;

    for ( i=0; i<DualWieldables.Length; ++i ) {
        if ( DualWieldables[i].Dual == Weapon )
            return true;
    }

    return false;
}

// if pickup is in inventory, then always returns true, even if bCheckForEquivalent = false,
// that way fixing picking up of the same weapon  -- PooSH
function bool IsInInventory(class<Pickup> PickupToCheck, bool bCheckForEquivalent, bool bCheckForVariant)
{
    local Inventory CurInv;
    local class<KFWeaponPickup> InvPickupClass;
    local class<KFWeaponPickup> WeaponPickupToCheck;
    local int i;

    if ( PickupToCheck == none )
        return false;

    WeaponPickupToCheck = class<KFWeaponPickup>(PickupToCheck);
    for ( CurInv = Pawn.Inventory; CurInv != none; CurInv = CurInv.Inventory ) {
        if ( /* bCheckForEquivalent && */ CurInv.default.PickupClass == PickupToCheck ) {
            if ( !bCheckForEquivalent && IsSinglePistol(class<KFWeapon>(CurInv.class)) )
                return false; // allow picking up a second pistol
            return true;
        }

        if( !bCheckForVariant )
            continue;

        // check if Item is variant of normal inventory item
        InvPickupClass = class<KFWeaponPickup>(CurInv.default.PickupClass);
        if( InvPickupClass != none ) {
            for( i = 0; i < InvPickupClass.default.VariantClasses.Length; ++i ) {
                if( InvPickupClass.default.VariantClasses[i] == PickupToCheck )
                    return true;
            }
        }
        // check if Item is normal version of variant inventory item
        if( WeaponPickupToCheck != none && CurInv.default.PickupClass != none ) {
            for( i = 0; i < WeaponPickupToCheck.default.VariantClasses.Length; ++i ) {
                if( WeaponPickupToCheck.default.VariantClasses[i] == CurInv.default.PickupClass )
                    return true;
            }
        }
    }

    return false;
}

exec function SetName(coerce string S)
{
    if ( S == "#" )
        S = PlayerName;

    if ( S == "" || (class'ScrnSrvReplInfo'.static.Instance().bForceSteamNames && Player.GUIController !=none
            && Player.GUIController.SteamGetUserName() != class'ScrnFunctions'.static.StripColorTags(S)) )
    {
        S = Player.GUIController.SteamGetUserName();
        if ( S == "" )
            PlayerName = "";
    }
    else {
        PlayerName = S;
    }
    ChangeName(S);
    UpdateURL("Name", S, true);
    SaveConfig();
}

function ChangeName( coerce string S )
{
    local string PlainName;

    S = Repl(S, " ", "_", true);
    S = Repl(S, "\"", "", true);
    S = Repl(S, "'", "", true);

    PlainName = class'ScrnFunctions'.static.StripColorTags(S);
    if ( len(PlainName) > 20 )
        S = left(PlainName, 20);

    if ( S ~= "WebAdmin" ) {
        S = "FakeAdmin_KillMe!";
    }

    Level.Game.ChangeName( self, S, true );
}

// TSC stuff

exec function SwitchTeam()
{
    if ( PlayerReplicationInfo == none || PlayerReplicationInfo.Team == None || PlayerReplicationInfo.Team.TeamIndex == 1 )
        ServerChangeTeam(0);
    else
        ServerChangeTeam(1);
}

exec function ChangeTeam( int N )
{
    ServerChangeTeam(N);
}

function ServerChangeTeam( int N )
{
    super.ServerChangeTeam(N);

    if ( Mut.bDynamicLevelCap && Mut.KF.bTradingDoorsOpen )
        Mut.DynamicLevelCap();
}

exec function SetupBase()
{
    ServerScoreFlag();
}

function ServerScoreFlag()
{
    local GameObject Flag;

    Flag = GameObject(PlayerReplicationInfo.HasFlag);
    if ( Flag != none ) {
        if ( Flag.bHeld )
            Flag.Score();
        else
            Flag.ClearHolder(); // shouldn't happen
    }
}

exec function AltFire( optional float F )
{
    if ( Level.Pauser == PlayerReplicationInfo )
    {
        SetPause(false);
        return;
    }
    if( bDemoOwner || (Pawn == None) )
        return;

    super.AltFire(F);
}

exec function ToggleDuck()
{
    if( bDuck == 0 ) {
        Crouch();
    }
    else {
        UnCrouch();
    }
}

exec function Crouch()
{
    if( Pawn == none )
        return;

    if ( !bTSCAdvancedKeyBindings && PlayerReplicationInfo.HasFlag != none
            && GameObject(PlayerReplicationInfo.HasFlag) != none
            && TSCGameReplicationInfo(Level.GRI) != none )
    {
        if ( bTSCAutoDetectKeys )
            bTSCAdvancedKeyBindings = ConsoleCommand("BINDINGTOKEY SetupBase") != "";
        if ( !bTSCAdvancedKeyBindings ) {
            SetupBase();
        }
    }

    super.Crouch();
}

exec function ThrowWeapon()
{
    if ( !bTSCAdvancedKeyBindings && GameObject(PlayerReplicationInfo.HasFlag) != none ) {
        if ( bTSCAutoDetectKeys )
            bTSCAdvancedKeyBindings = ConsoleCommand("BINDINGTOKEY DropFlag") != "";
        if ( !bTSCAdvancedKeyBindings ) {
            DropFlag();
            return;
        }
    }
    ServerThrowWeapon();
}

simulated function float RateWeapon(Weapon w)
{
    if ( bPrioritizePerkedWeapons ) {
        if ( ScrnPawn != none && ScrnPawn.IsPerkedWeapon(KFWeapon(W)) ) {
            return 256.f + w.Default.Priority;
        }
    }

    return w.Default.Priority;
}

// character selection
simulated function bool IsTeamCharacter(string CharacterName)
{
    if ( CharacterName == "" )
        return false;

    if ( Level.GRI.bNoTeamSkins || TSCGameReplicationInfo(Level.GRI) == none || PlayerReplicationInfo == none || PlayerReplicationInfo.Team == none )
        return true; // no team = any character can be used

    if ( PlayerReplicationInfo.Team.TeamIndex == 0 )
        return IsRedCharacter(CharacterName);
    else if ( PlayerReplicationInfo.Team.TeamIndex == 1 )
        return IsBlueCharacter(CharacterName);

    return false;
}

simulated function bool IsRedCharacter(string CharacterName)
{
    local int i;

    if ( CharacterName == "" )
        return false;

    for ( i=0; i<RedCharacters.Length; ++i )
        if ( RedCharacters[i] ~= CharacterName )
            return true;

    return false;
}

simulated function bool IsBlueCharacter(string CharacterName)
{
    local int i;

    if ( CharacterName == "" )
        return false;

    for ( i=0; i<BlueCharacters.Length; ++i )
        if ( BlueCharacters[i] ~= CharacterName )
            return true;

    return false;
}

exec function ChangeCharacter(string newCharacter, optional string inClass)
{
    local ClientPerkRepLink L;

    if ( newCharacter == "" || !IsTeamCharacter(newCharacter) )
        return;

    L = class'ScrnClientPerkRepLink'.static.FindMe(self);
    if( L!=None )
        L.SelectedCharacter(newCharacter);
    else
        Super(KFPlayerController_Story).ChangeCharacter(newCharacter,inClass);
}

function SetPawnClass(string inClass, string inCharacter)
{
    ValidateCharacter(inCharacter);
    super.SetPawnClass(inClass, inCharacter);
}

/**
 * Checks if character can be used on this player.
 * @param   CharacterName   [in]    name of the character to validate (xUtil.PlayerRecord.DefaultName)
 *                          [out]   name of the valid character
 * @return  True, if given character can be used. CharacterName stays unchanged.
 *          False,  if given character is invalid. CharacterName changed to valid character.
 */
simulated function bool ValidateCharacter(out string CharacterName)
{
    if ( IsTeamCharacter(CharacterName) )
        return true;

    if ( PlayerReplicationInfo.Team.TeamIndex == 0 ) {
        if ( RedCharacter != "" && IsRedCharacter(RedCharacter) )
            CharacterName = RedCharacter; // only on client side
        else
            CharacterName = RedCharacters[0];
    }
    else if ( PlayerReplicationInfo.Team.TeamIndex == 1 ) {
        if ( BlueCharacter != "" && IsBlueCharacter(BlueCharacter) )
            CharacterName = BlueCharacter; // only on client side
        else
            CharacterName = BlueCharacters[0];
    }
    return false;
}

function SendSelectedVeterancyToServer(optional bool bForceChange)
{
    local class<KFVeterancyTypes> OldPerk;

    if( Level.NetMode!=NM_Client && SRStatsBase(SteamStatsAndAchievements)!=none ) {
        OldPerk = KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill;
        SRStatsBase(SteamStatsAndAchievements).WaveEnded();
        if ( OldPerk != KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill )
            PerkChangeWave = KFGameType(Level.Game).WaveNum;
    }
}

function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange)
{
    local ScrnClientPerkRepLink L;

    L = class'ScrnClientPerkRepLink'.Static.FindMe(self);

    if ( L != none ) {
        L.ServerSelectPerkSE(Class<ScrnVeterancyTypes>(VetSkill));
    }
}

exec function Perk(coerce string PerkName)
{
    local class<ScrnVeterancyTypes> newPerk;
    local KFPlayerReplicationInfo KFPRI;
    local class<ScrnVeterancyTypes> myPerk;

    if (PerkName == "") {
        class'ScrnFunctions'.static.SendPerkList(self);
        return;
    }

    KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
    if (KFPRI == none)
        return;
    myPerk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);

    newPerk = class'ScrnFunctions'.static.FindPerkByName(class'ScrnClientPerkRepLink'.Static.FindMe(self), PerkName);
    if (newPerk == none) {
        ConsoleMessage(strPerkNotAvailable);
        return;
    }
    SelectVeterancy(newPerk);
}

exec final function TourneyCheck()
{
    ServerTourneyCheck();
}

final function ServerTourneyCheck()
{
    local ScrnGameType GT;
    local Mutator M;
    local GameRules G;
    local string s;
    local int TourneyMode;

    ClientMessage(string(Level.Game.class));

    GT = ScrnGameType(Level.Game);
    if ( GT == none )
        ClientMessage("Current game type doesn't support Tourney Mode");
    else {
        if ( GT.IsTourney() ) {
            TourneyMode = GT.GetTourneyMode();
            s = "";
            if ( (TourneyMode & GT.TOURNEY_VANILLA) != 0 )
                s @= "VANILLA";
            if ( (TourneyMode & GT.TOURNEY_SWP) != 0 )
                s @= "SWP";
            if ( (TourneyMode & GT.TOURNEY_ALL_WEAPONS) != 0 )
                s @= "ALL_WEAPONS";
            if ( (TourneyMode & GT.TOURNEY_ALL_PERKS) != 0 )
                s @= "ALL_PERKS";
            if ( (TourneyMode & GT.TOURNEY_HMG) != 0 )
                s @= "HMG";
            if ( s != "" )
                s = " (" $ s $ " )";
            ClientMessage("Tourney Mode: " $ GT.GetTourneyMode() $ s);
        }
        else {
            ClientMessage("Tourney Mode DISABLED");
        }
    }
    s = "Mutators:";
    for ( M = Level.Game.BaseMutator; M != None; M = M.NextMutator )
        s @= string(M.class);
    LongMessage(s, 80, " ");
    ServerMutate("VERSION");

    s = "Rules:";
    for ( G=Level.Game.GameRulesModifiers; G!=None; G=G.NextGameRules )
        s @= string(G.class);
    LongMessage(s, 80, " ");
}

exec final function AdminKillMut(string MutName)
{
    if ( Level.NetMode == NM_Standalone || (PlayerReplicationInfo != none && PlayerReplicationInfo.bAdmin) )
        ServerKillMut(MutName);
}

final function ServerKillMut(string MutatorName)
{
    local Mutator M;
    local ScrnBalance SBM;

    if ( Level.NetMode != NM_Standalone && (PlayerReplicationInfo == none || !PlayerReplicationInfo.bAdmin) )
        return;

    if ( MutatorName ~= "KillingFloorMut" || MutatorName ~= "ScrnBalance" || MutatorName ~= "ServerPerksMut" )
        return;

    SBM = class'ScrnBalance'.static.Myself(Level);
    if ( SBM == none || GetItemName(string(SBM.class)) ~= MutatorName
            || GetItemName(string(SBM.FindServerPerksMut().class)) ~= MutatorName )
        return; // can't kill ScrnBalance or ServerPerks

    for ( M = Level.Game.BaseMutator; M != None; M = M.NextMutator ) {

        if ( GetItemName(string(M.class)) ~= MutatorName ) {
            ClientMessage("Mutator '"$string(M.Class)$"' destroyed");
            M.Destroy();
            return;
        }
    }
}

exec final function AdminKillRules(string RuleName)
{
    if ( Level.NetMode == NM_Standalone || (PlayerReplicationInfo != none && PlayerReplicationInfo.bAdmin) )
        ServerKillRules(RuleName);
}

final function ServerKillRules(string RuleName)
{
    local GameRules G, PrevG;

    if ( Level.NetMode != NM_Standalone && (PlayerReplicationInfo == none || !PlayerReplicationInfo.bAdmin) )
        return;

    if ( RuleName ~= "SRGameRules" || RuleName ~= "ScrnGameRules" )
        return; // can't kill ScrnGameRules

    PrevG = Level.Game.GameRulesModifiers;
    if ( GetItemName(string(PrevG.class)) ~= RuleName ) {
        ClientMessage("Game Rules '"$string(PrevG.Class)$"' destroyed");
        Level.Game.GameRulesModifiers = PrevG.NextGameRules;
        PrevG.Destroy();
    }
    else {
        for ( G=PrevG.NextGameRules; G!=None; PrevG=G ) {
            if ( GetItemName(string(G.class)) ~= RuleName ) {
                PrevG.NextGameRules = G.NextGameRules;
                ClientMessage("Game Rules '"$string(G.Class)$"' destroyed");
                G.Destroy();
                return;
            }
        }
    }
}


function CheckDLC()
{
    local ScrnSteamStatsGetter A;

    foreach AllActors(class'ScrnSteamStatsGetter', A)
        return; // do not allow duplicates

    spawn(class'ScrnSteamStatsGetter',self);
}

// returns true if players owns DLC
function bool OwnsDLC(int AppID)
{
    local int i;
    local bool bNeedCheck;

    for ( i=0; i<DLC.length; ++i ) {
        bNeedCheck = bNeedCheck || !DLC[i].bChecked;
        if ( DLC[i].AppID == AppID)
            break;
    }
    if ( i == DLC.length ) {
        DLC.insert(i, 1);
        DLC[i].AppID = AppID;
    }

    if ( bNeedCheck )
        CheckDLC(); // this doesn't happen immediately, so function returns false in the first try

    return DLC[i].bOwnsDLC;
}

/**
 * Sets gun skin according to index in pickup's VariantClasses[]. Check DLC locks.
 *
 * @param index     Skin index:
 *                  0 - switch to next skin
 *                  1 - switch to default skin
 *                  2+  switch to skin defined in Weapon.PickupClass.VariantClasses array.
 *                      2 - first item in array (VariantClasses[0]), 3 - second (VariantClasses[1]) etc.
 * @param bTryNext  If this skin is locked (DLC), then should we try selecting next skin?
 */
exec function GunSkin(optional byte index, optional bool bTryNext)
{
    local KFWeapon W;
    local class<KFWeaponPickup> P;
    local int i;
    local class<KFWeapon> SkinnedWeaponClass;
    local byte k;

    if ( Pawn == none || Pawn.Weapon == none )
        return;
    W = KFWeapon(Pawn.Weapon);
    P = class<KFWeaponPickup>(Pawn.Weapon.PickupClass);
    if ( W == none || P == none || P.default.VariantClasses.Length == 0 )
        return;

    if ( W.SleeveNum == 0 )
        k = 1; // for weapons where hand skin is first in array

    if ( k >= W.Skins.length ) {
        warn(W.class $ " has no skins");
        return;
    }

    if ( index == 0 ) {
        bTryNext = true;
        // find out current skin
        if ( W.Skins[k] == W.default.Skins[k] )
            index = 1; // default skin
        else {
            for ( i=0; i<P.default.VariantClasses.Length; ++i ) {

                if ( P.default.VariantClasses[i] == none ) {
                    //bugfix
                    P.default.VariantClasses.remove(i--, 1);
                }
                else if (W.Skins[k] == P.default.VariantClasses[i].default.InventoryType.default.Skins[k]) {
                    if (index == 0) {
                        index = i + 2;
                    }
                    else {
                        // remove duplicates
                        P.default.VariantClasses.remove(i--, 1);
                    }
                }
            }
        }
        if ( P.default.VariantClasses.Length == 0 )
            return; // bugfix, when VariantClasses have "none" elements
        index++;
    }

    if ( index >= P.default.VariantClasses.Length+2 )
        index = 1;

    if ( index == 1 ) {
        // load default skin
        SkinnedWeaponClass = W.class;
    }
    else {
        // load skin from variant class
        SkinnedWeaponClass = class<KFWeapon>(P.default.VariantClasses[index-2].default.InventoryType);
        // DLC check
        if ( SkinnedWeaponClass == none || (!Mut.bBeta && SkinnedWeaponClass.default.AppID > 0
                && !OwnsDLC(SkinnedWeaponClass.default.AppID)) )
        {
            // this skin is locked
            if ( bTryNext )
                GunSkin(index+1, true); // try next one
            return;
        }
    }

    if ( SkinnedWeaponClass == none )
        return;
    ClientWeaponSpawned(SkinnedWeaponClass, none); // preload assets
    SkinnedWeaponClass.static.PreloadAssets(W);
    W.HandleSleeveSwapping(); // restore proper arms
    ServerGunSkin(SkinnedWeaponClass);

    // save skin in user.ini
    for ( i=0; i<WeaponSettings.length; ++i )
        if ( W.class == WeaponSettings[i].Weapon )
            break;
    if ( i == WeaponSettings.length ) {
        WeaponSettings.insert(i,1);
        WeaponSettings[i].Weapon = W.class;
    }
    if ( WeaponSettings[i].SkinIndex != index ) {
        WeaponSettings[i].SkinIndex = index;
        WeaponSettings[i].LastWeapon = W;
        SaveConfig();
    }
}

// replicate attachment (3-rd person model) skin to other players
function ServerGunSkin(class<KFWeapon> SkinnedWeaponClass)
{
    local Controller C;
    local int i;
    local KFWeapon W;

    // preload assets
    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if ( C != self && KFPlayerController(C) != none )
            KFPlayerController(C).ClientWeaponSpawned(SkinnedWeaponClass, none);
    }

    if ( Pawn != none )
        W = KFWeapon(Pawn.Weapon);
    if ( W != none && W.AttachmentClass != SkinnedWeaponClass.default.AttachmentClass ) {
        W.ThirdPersonActor.Destroy();
        W.ThirdPersonActor = none;
        W.AttachmentClass = SkinnedWeaponClass.default.AttachmentClass;
        W.AttachToPawn(Pawn);

        //remember weapon choise
        for ( i=0; i<WeaponSettings.length; ++i )
            if ( W.class == WeaponSettings[i].Weapon )
                break;
        if ( i == WeaponSettings.length ) {
            WeaponSettings.insert(i,1);
            WeaponSettings[i].Weapon = W.class;
        }
        WeaponSettings[i].SkinnedWeapon = SkinnedWeaponClass;
    }
}

function LoadGunSkinFromConfig()
{
    local int i;

    if ( Pawn == none || Pawn.Weapon == none )
        return;

    for ( i=0; i<WeaponSettings.length; ++i ) {
        if ( Pawn.Weapon.class == WeaponSettings[i].Weapon ) {
            if ( WeaponSettings[i].LastWeapon != Pawn.Weapon )
                GunSkin(WeaponSettings[i].SkinIndex);
            break;
        }
    }
}

// overrided KFWeapon behavior to block reloading while putting down, bringing up or throwing the nade
exec function ReloadMeNow()
{
    local KFWeapon W;

    if ( Pawn != none )
        W = KFWeapon(Pawn.Weapon);
    if ( W == none )
        return;

    // ClientMessage( "Reloading Weapon: "
        // @ "Timer=" $ W.TimerCounter$"/"$W.TimerRate
        // @ "ClientState=" $ GetEnum(Enum'EWeaponClientState', W.ClientState)
        // @ "ClientGrenadeState=" $ GetEnum(Enum'EClientGrenadeState', W.ClientGrenadeState)
    // );

    if ( W.ClientState == WS_ReadyToFire /* && W.ClientGrenadeState == GN_None */ )
        W.ReloadMeNow();
}

exec function GetWeapon(class<Weapon> NewWeaponClass )
{
    if ( ScrnPawn != none && ScrnPawn.bQuickMeleeInProgress )
        return;
    super.GetWeapon(NewWeaponClass);
}

exec function NextWeapon()
{
    if ( ScrnPawn != none && ScrnPawn.bQuickMeleeInProgress )
        return;
    super.NextWeapon();
}

exec function PrevWeapon()
{
    if ( ScrnPawn != none && ScrnPawn.bQuickMeleeInProgress )
        return;
    super.PrevWeapon();
}


// STATES

state Dead
{
    function BeginState()
    {
        super.BeginState();
        OnPawnChanged();
    }

    // fix of null-reference
    function Timer()
    {
        local KFGameType KF;
        local ScrnGameType ScrnGT;
        local bool bRestartMe;

        KF = KFGameType(Level.Game);
        ScrnGT = ScrnGameType(Level.Game);

        if ( KF != none && Level.Game.GameReplicationInfo.bMatchHasBegun ) {
            if ( ScrnGT != none ) {
                bRestartMe = ScrnGT.PlayerCanRestart(self);
            }
            else if ( KFStoryGameInfo(Level.Game) != none ) {
                bRestartMe = KFStoryGameInfo(Level.Game).IsTraderTime();
            }
            else {
                bRestartMe = !bSpawnedThisWave && !KF.bWaveInProgress;
            }
        }

        if ( bRestartMe ) {
            PlayerReplicationInfo.Score = Max(KF.MinRespawnCash, int(PlayerReplicationInfo.Score));
            SetViewTarget(self);
            ClientSetBehindView(false);
            bBehindView = False;
            ClientSetViewTarget(Pawn);
            PlayerReplicationInfo.bOutOfLives = false;
            if ( Pawn != none ) {
                // wtf?
                Pawn = none;
                OnPawnChanged();
            }
            ServerReStartPlayer();
        }
        super(xPlayer).Timer();
    }
}

    // view next player
function ServerViewNextPlayer()
{
    local Controller C, Pick;
    local bool bFound, bWasSpec;

    if( !IsInState('Spectating') )
        return;

    if ( ScrnGameType(Level.Game) == none ) {
        super.ServerViewNextPlayer();
        ViewTargetChanged();;
        return;
    }

    // copy-pasted to remove team hack
    bWasSpec = !bBehindView && (ViewTarget != Pawn) && (ViewTarget != self);
    for ( C=Level.ControllerList; C!=None; C=C.NextController ) {
        if ( Level.Game.CanSpectate(self,PlayerReplicationInfo.bOnlySpectator,C) ) {
            if ( Pick == None )
                Pick = C;
            if ( bFound ) {
                Pick = C;
                break;
            }
            else
                bFound = RealViewTarget == C || ViewTarget == C;
        }
    }
    if ( Pick == none )
        Pick = self;
    SetViewTarget(Pick);
    ClientSetViewTarget(Pick);
    if ( (ViewTarget == self) || bWasSpec )
        bBehindView = false;
    else
        bBehindView = true; //bChaseCam;
    ClientSetBehindView(bBehindView);
    ViewTargetChanged();
}

function ServerViewSelf()
{
    local Actor A;
    local vector Loc;
    local rotator R;

    if ( !AllowFreeCamera() ) {
        ServerViewNextPlayer();
        return;
    }

    if ( bBehindView ) {
        PlayerCalcView(A, Loc, R);
    }
    else {
        Loc = ViewTarget.Location;
        R = ViewTarget.Rotation;
    }
    SetLocation(Loc);
    SetRotation(R);
    ClientSetLocation(Loc, R);

    bBehindView = false;
    SetViewTarget(self);
    ClientSetViewTarget(self);
    ClientMessage(OwnCamera, 'Event');
    ViewTargetChanged();
}


// Modes:
// 1 - switch to next team
// 2 - switch to flag carrier
// 3 - cycle through the team
// 4 - assign favorite player
// 5 - cycle between 2 favorite players
// 6 - cycle between big zeds (base HP >= 1000)
// 7 - cycle between Fleshpounds and Patriarch
function ServerSwitchViewMode(byte Mode)
{
    local Controller C, Pick, CurrentTarget;
    local bool bFound;
    local TeamInfo ViewingTeam;

    if( !IsInState('Spectating') || !PlayerReplicationInfo.bOnlySpectator )
        return;

    if ( ScrnGameType(Level.Game) == none )
        return;

    CurrentTarget = Controller(ViewTarget);
    if ( CurrentTarget == none ) {
        if ( Pawn(ViewTarget) != none )
            CurrentTarget = Pawn(ViewTarget).Controller;
        else
            CurrentTarget = RealViewTarget;
    }

    if ( CurrentTarget != none && CurrentTarget.PlayerReplicationInfo != none )
        ViewingTeam = CurrentTarget.PlayerReplicationInfo.Team;


    if ( Mode == 4 ) {
        if ( CurrentTarget == none )
            return;

        FavoriteSpecs[1] = FavoriteSpecs[0];
        FavoriteSpecs[0] = CurrentTarget;
        ClientMessage(strSpecFavoriteAssigned);
        return;
    }
    else if ( Mode == 5 ) {
        if ( FavoriteSpecs[0] == none && FavoriteSpecs[1] == none ) {
            ClientMessage(strSpecNoFavorites);
            return;
        }

        if ( FavoriteSpecs[0] == CurrentTarget )
            Pick = FavoriteSpecs[1];
        else
            Pick = FavoriteSpecs[0];
    }
    else if ( Mode == 6 || Mode == 7 ) {
        // view next Fleshpound / Patriarch
        for ( C=Level.ControllerList; C!=None; C=C.NextController ) {
            if ( C.Pawn == none || C.Pawn.Health <= 0 || C.Pawn.default.Health < 1000 || KFMonsterController(C) == none )
                continue;

            if ( Mode == 7 && FleshpoundZombieController(C) == none && BossZombieController(C) == none )
                continue;

            if ( CurrentTarget == C )
                bFound = true;
            else if ( Pick == None || bFound ) {
                Pick = C;
                if ( bFound )
                    break;
            }
        }
    }
    else {
        // view next player
        for ( C=Level.ControllerList; C!=None; C=C.NextController ) {
            if ( C.PlayerReplicationInfo == none )
                continue;

            if ( Level.Game.CanSpectate(self,true,C) ) {
                if ( CurrentTarget == C )
                    bFound = true;
                else if ( Pick == None || bFound ) {
                    if ( (Mode == 1 && ViewingTeam != C.PlayerReplicationInfo.Team)
                            || (Mode == 2 && C.PlayerReplicationInfo.HasFlag != none)
                            || (Mode == 3 && ViewingTeam == C.PlayerReplicationInfo.Team))
                    {
                        Pick = C;
                        if ( bFound || Mode == 1 )
                            break;
                    }
                }

            }
        }
    }

    if ( Pick == none )
        return;

    ServerSetViewTarget(Pick);
}

function ServerSetViewTarget(Actor NewViewTarget)
{
    local bool bWasSpec;

    if ( !IsInState('Spectating') )
        return;

    if ( !AllowFreeCamera() )
        return;

    bWasSpec = !bBehindView && ViewTarget != Pawn && ViewTarget != self;
    SetViewTarget(NewViewTarget);
    ViewTargetChanged();
    ClientSetViewTarget(NewViewTarget);
    if ( ViewTarget == self || bWasSpec )
        bBehindView = false;
    else
        bBehindView = true; //bChaseCam;
    ClientSetBehindView(bBehindView);
}

function ViewTargetChanged()
{
    local Controller C;
    local ScrnHumanPawn ScrnVT;

    //log("ViewTargetChanged("$OldViewTarget$")", 'ScrnBalance');

    if ( Role < ROLE_Authority || !AllowFreeCamera() )
        return;

    ScrnVT = ScrnHumanPawn(OldViewTarget);
    if ( ScrnVT != none && ScrnVT != ViewTarget ) {
        // check if somebody else is spectating our old target
        for ( C=Level.ControllerList; C!=None; C=C.NextController ) {
            if ( C.Pawn != ScrnVT && PlayerController(C) != none && PlayerController(C).ViewTarget == ScrnVT )
                break;
        }
        ScrnVT.bViewTarget = C!=none;
    }

    ScrnVT = ScrnHumanPawn(ViewTarget);
    if ( ScrnVT != none )
            ScrnVT.bViewTarget = true; // tell pawn that we are watching him

    OldViewTarget = ViewTarget;
}

function ClientSetBehindView(bool B)
{
    super.ClientSetBehindView(B);

    if ( PlayerReplicationInfo != none && PlayerReplicationInfo.bOnlySpectator ) {
        // auto show crosshair in first person spectator mode
        if ( ScrnHUD(MyHUD) != none )
            ScrnHUD(MyHUD).DebugCrosshair(!bBehindView);
    }
    else if ( !bBehindView ) {
        bFreeCamera = false;
    }
}

exec function FreeCamera( bool B )
{
    ClientMessage("FreeCamera is blocked due to exploits. Use ToggleBehindView instead");
}

// BehindView() executes on the server-side only. Should be called ServerBehindView()
exec function BehindView( Bool B )
{
    if ( B && Pawn != None && !IsSpectating() && (!Mut.bAllowBehindView || Mut.bTSCGame) ) {
        return;
    }
    super.BehindView(B);
}

function ServerToggleBehindView()
{
    if ( !bBehindView && Pawn != None && !IsSpectating() && (!Mut.bAllowBehindView || Mut.bTSCGame) ) {
        return;
    }
    super.ServerToggleBehindView();
}

function bool AllowFreeCamera()
{
    return PlayerReplicationInfo.bOnlySpectator || !Level.GRI.bMatchHasBegun
            || (!Mut.bTSCGame && Mut.SrvTourneyMode == 0);
}


state Spectating
{
    function BeginState()
    {
        super.BeginState();

        if ( !bFrozen && !AllowFreeCamera() ) {
            ServerViewNextPlayer();
        }
    }

    function Timer()
    {
        bFrozen = false;
        if ( !AllowFreeCamera() ) {
            ServerViewNextPlayer();
        }
    }

   // Return to spectator's own camera.
    exec function AltFire( optional float F )
    {
        if ( AllowFreeCamera() )
            super.AltFire(F);
        else
            Fire(F);
    }

    exec function SwitchWeapon(byte T)
    {
        if ( PlayerReplicationInfo.bOnlySpectator )
            ServerSwitchViewMode(T);
    }

    exec function Use()
    {
        local vector HitLocation, HitNormal, TraceEnd, TraceStart;
        local rotator R;
        local Actor A;

        PlayerCalcView(A, TraceStart, R);
        TraceEnd = TraceStart + 1000 * Vector(R);
        A = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true);
        if ( Pawn(A) != none)
            ServerSetViewTarget(A);
    }
}


// ============================== DEBUG STUFF ==============================

// ========================== UNHARMFUL FUNCTIONS ==========================
exec function TestColorTags(coerce string ColorTagString, optional int i)
{
    local string c, s;

    c = class'ScrnFunctions'.static.ParseColorTags(ColorTagString, PlayerReplicationInfo);
    s = class'ScrnFunctions'.static.StripColorTags(ColorTagString);
    if ( i > 0) {
        c = class'ScrnFunctions'.static.LeftCol(c, i);
        s = left(s, i);
    }
    ConsoleMessage(c);
    ConsoleMessage(s);
}


exec function MyTeam()
{
    if ( PlayerReplicationInfo == none )
        ClientMessage("No PlayerReplicationInfo received yet");
    else if ( PlayerReplicationInfo.Team == none )
        ClientMessage("Team is not selected");
    else
        ClientMessage("My Team Index = " $ PlayerReplicationInfo.Team.TeamIndex
            $ " ("$ PlayerReplicationInfo.Team.class$")");
}



function DebugRepLink(string S)
{
    local ClientPerkRepLink L;
    local ScrnClientPerkRepLink SL;
    local int count;

    if ( Role < ROLE_Authority ) {
        foreach DynamicActors(Class'ClientPerkRepLink',L) {
            ++count;
        }
        if ( count != 1 ) {
            if ( count == 0 )
                ClientMessage(S @ "WARNING! No RepLink objects found!", 'Log');
            else
                ClientMessage(S @ "WARNING! Multiple RepLink objects found! ("$count$")", 'Log');
        }
        L = Class'ScrnClientPerkRepLink'.Static.FindMe(self);
        ClientMessage(S @ "RepLink: " $ L, 'Log');
    }
    else {
        L = SRStatsBase(SteamStatsAndAchievements).Rep;
        ClientMessage(S @ "Stats: " $ SteamStatsAndAchievements, 'Log');
        ClientMessage(S @ "Stats.Rep: " $ L, 'Log');
    }

    ClientMessage(S @ "Categories ACK/TOTAL: " $ L.ClientAccknowledged[1]$"/"$L.ShopCategories.Length, 'Log');
    ClientMessage(S @ "Weapons    ACK/TOTAL: " $ L.ClientAccknowledged[0]$"/"$L.ShopInventory.Length, 'Log');
    ClientMessage(S @ "Characters ACK/TOTAL: " $ L.ClientAckSkinNum$"/"$L.CustomChars.Length, 'Log');

    SL = ScrnClientPerkRepLink(L);
    if ( SL != none ) {
        ClientMessage(S @ "Job: " $ SL.CurrentJob, 'Log');
    }
}

function ServerDebugRepLink()
{
    if ( Role == ROLE_Authority )
        DebugRepLink("Server");
}

exec function TestRepLink()
{
    DebugRepLink("Client");
    if ( Role < ROLE_Authority )
        ServerDebugRepLink();
}

exec function RestartRepLink()
{
    local ScrnClientPerkRepLink L;

    if ( KFGameReplicationInfo(Level.GRI).EndGameType > 0 ) {
        ClientMessage("Unable to restart replication when game ended.");
        return;
    }

    L = Class'ScrnClientPerkRepLink'.Static.FindMe(self);
    if ( L == none ) {
        ClientMessage("ScrnClientPerkRepLink not found");
        return;
    }
    bDebugRepLink = true;
    L.StartClientInitialReplication();
}

exec function RepLinkMessages(bool value)
{
    bDebugRepLink = value;
    Class'ScrnClientPerkRepLink'.Static.FindMe(self).bClientDebug = bDebugRepLink;
}

exec function TestQuickMelee()
{
    local Inventory inv;
    local KFWeapon W;
    local string s;
    local int c;

    if ( ScrnPawn == none )
        return;

    for ( inv = Pawn.Inventory; inv != none && ++c < 1000 ; inv = inv.Inventory ) {
        W = KFWeapon(inv);
        if ( W != none ) {
            if ( W == Pawn.Weapon )
                s = "[CURRENT]";
            else
                s = "";
            s @= W.ItemName $ ": ClientState=" $ GetEnum(Enum'EWeaponClientState', W.ClientState);
            s @= "ClientGrenadeState=" $ GetEnum(Enum'EClientGrenadeState', W.ClientGrenadeState);
            ClientMessage(s, 'log');
        }
    }
    ClientMessage("SecondaryItem: " $ ScrnPawn.SecondaryItem, 'log');
    if ( ScrnPawn.SecondaryItem != none ) {
        ClientMessage("SecondaryItem State: " $ ScrnPawn.SecondaryItem.GetStateName(), 'log');
    }
}

exec function FixQuickMelee()
{
    local Inventory inv;
    local KFWeapon W;
    local int c;

    if ( Pawn == none )
        return;

    if ( Level.NetMode == NM_Client ) {
        ServerFixQuickMelee();  // do the same on server
    }

    KFPawn(Pawn).SecondaryItem = none;
    KFPawn(Pawn).bThrowingNade = false;

    for ( inv = Pawn.Inventory; inv != none && ++c < 1000 ; inv = inv.Inventory ) {
        W = KFWeapon(inv);
        if ( W != none ) {
            if ( W != Pawn.Weapon ) {
                W.ClientState = WS_Hidden;
            }
            W.ClientGrenadeState = GN_None;
            W.SetTimer(0, false);
            W.GotoState('');
        }
    }

    if ( Pawn.Weapon != none && Pawn.Weapon.ClientState != WS_ReadyToFire ) {
        Pawn.Weapon.ClientState = WS_Hidden;
        KFWeapon(Pawn.Weapon).ClientGrenadeState = GN_BringUp;
        Pawn.Weapon.BringUp();
    }
}

function ServerFixQuickMelee()
{
    if ( Level.NetMode != NM_Client ) {
        FixQuickMelee();
    }
}

exec function Crap(optional int Amount)
{
    if ( Level.TimeSeconds < NextCrapTime )
        return;

    NextCrapTime = Level.TimeSeconds + 0.5;
    ServerCrap(Amount);
}

function ServerCrap(int Amount)
{
    if ( ScrnPawn != none ) {
        ScrnPawn.Crap(Amount);
    }
}

exec function DebugZedSpawn()
{
    if ( Mut.CheckScrnGT(self) ) {
        Mut.ScrnGT.ToggleDebugZedSpawn();
    }
}

// ======================== COMMENT BEFORE RELEASE !!! =====================

// exec function SetSID64(coerce string SteamID64)
// {
//    if ( Mut.CheckAdmin(self) )
//         class'ScrnCustomPRI'.static.FindMe(PlayerReplicationInfo).SetSteamID64(SteamID64);
// }
//
// exec function TestSID()
// {
//     SetSID64("76561197992537591");
// }
//
// exec function PerkLevel(int L)
// {
//    if ( Mut.CheckAdmin(self) )
//         KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkillLevel = L;
// }
//
// exec function TestZedTime(optional float DesiredZedTimeDuration)
// {
//     if ( Mut.CheckAdmin(self) )
//         KFGameType(Level.Game).DramaticEvent(1.0, DesiredZedTimeDuration);
// }
//
// exec function IncAch(name AchID)
// {
//     if ( Mut.CheckAdmin(self) )
//         class'ScrnAchCtrl'.static.ProgressAchievementByID(Class'ScrnClientPerkRepLink'.Static.FindMe(self), AchID, 1);
// }
//
// exec function GiveAch(name AchID)
// {
//     if ( Mut.CheckAdmin(self) )
//         class'ScrnAchCtrl'.static.ProgressAchievementByID(Class'ScrnClientPerkRepLink'.Static.FindMe(self), AchID, 1000);
// }
//
// exec function BuyAll()
// {
//     local int i;
//     local ScrnClientPerkRepLink L;
//
//     if ( Role != ROLE_Authority )
//         return;
//
//     PlayerReplicationInfo.Score = 1000000;
//     L = class'ScrnClientPerkRepLink'.static.FindMe(self);
//     for ( i=0; i<L.ShopInventory.length; ++i ) {
//         ScrnPawn.DropAllWeapons(ScrnPawn);
//         ScrnPawn.ServerBuyWeapon(class<Weapon>(L.ShopInventory[i].PC.default.InventoryType), 0);
//     }
// }
//
//
// exec function GiveSpawnInv()
// {
//     if ( Role != ROLE_Authority )
//         return;
//
//     KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.AddDefaultInventory(KFPlayerReplicationInfo(PlayerReplicationInfo), Pawn);
// }
//
// exec function TestEndGame()
// {
//     if ( Role != ROLE_Authority )
//         return;
//
//     Mut.GameRules.bSuperPat = true;
//     Mut.GameRules.bHasCustomZeds = true;
//     Mut.GameRules.GameDoom3Kills = 100;
//     Mut.GameRules.HardcoreLevel = 15;
//     Mut.KF.WaveNum = Mut.KF.FinalWave + 1;
//     Mut.KF.CheckEndGame(PlayerReplicationInfo, "Test");
// }
//
// exec function BecomeAhmed(bool b)
// {
//     if ( Role != ROLE_Authority )
//         return;
//
//     if (b) {
//         class'ScrnSuicideBomb'.static.MakeSuicideBomber(Pawn);
//     }
//     else {
//         class'ScrnSuicideBomb'.static.DisintegrateAll(Level);
//     }
// }
//
// exec function SilenceIKillYou()
// {
//     if ( Role != ROLE_Authority )
//         return;
//
//     class'ScrnSuicideBomb'.static.ExplodeAll(Level);
// }


defaultproperties
{
    bManualReload=True
    DamageAck=1  // make show the default value is the same as ScrnHUD.ShowDamages
    DamageNumbersClass=class'ScrnDamageNumbers'
    AchievementDisplayCooldown=5.000000
    bChangedPerkDuringGame=True
    Custom3DScopeSens=24
    ProfilePageClassString="ScrnBalanceSrv.ScrnProfilePage"
    LobbyMenuClassString="ScrnBalanceSrv.ScrnLobbyMenu"
    TSCLobbyMenuClassString="ScrnBalanceSrv.TSCLobbyMenu"
    PawnClass=class'ScrnHumanPawn'
    CustomPlayerReplicationInfoClass=class'ScrnCustomPRI'
    FlareCloudClass=class'ScrnFlareCloud'
    bSpeechVote=true
    bAlwaysDisplayAchProgression=true
    MaxVoiceMsgIn10s=5
    strLocked="Weapon pickups LOCKED"
    strUnlocked="Weapon pickups UNLOCKED"
    strLockDisabled="Weapon lock is disabled by server"
    strAlreadySpectating="Already spectating. Type READY, if you want to join the game."
    strNoPerkChanges="Mid-game perk changes disabled"
    strPerkLocked="Perk is locked"
    strPerkNotAvailable="Perk is not available"
    strMutateProtection="Cannot mutate too often. Wait a bit."
    bWaveGarbageCollection=False
    bOtherPlayerLasersBlue=true

    DualWieldables(0)=(Single=class'KFMod.Single',Dual=class'KFMod.Dualies')
    DualWieldables(1)=(Single=class'KFMod.Deagle',Dual=class'KFMod.DualDeagle')
    DualWieldables(2)=(Single=class'KFMod.GoldenDeagle',Dual=class'KFMod.GoldenDualDeagle')
    DualWieldables(3)=(Single=class'KFMod.Magnum44Pistol',Dual=class'KFMod.Dual44Magnum')
    DualWieldables(4)=(Single=class'KFMod.MK23Pistol',Dual=class'KFMod.DualMK23Pistol')
    DualWieldables(5)=(Single=class'KFMod.FlareRevolver',Dual=class'KFMod.DualFlareRevolver')

    strSpecFavoriteAssigned="View target marked as favorite"
    strSpecNoFavorites="No favorite view targets! Press '4' to assign favorite."

    DLC(0)=(AppID=210934)
    DLC(1)=(AppID=210938)
    DLC(2)=(AppID=210939)
    DLC(3)=(AppID=210942)
    DLC(4)=(AppID=210943)
    DLC(5)=(AppID=210944)
    DLC(6)=(AppID=258751)
    DLC(7)=(AppID=258752)
    DLC(8)=(AppID=309991)

    strPlayingSong="Now playing: "
    MusicPlaylistNames(0)="<DEFAULT>"
    MusicPlaylistNames(1)="KF1 Classic Soundtrack"
    MusicPlaylistNames(2)="DooM Metal Soundtrack"

    MyMusic( 0)=(PL=1,Wave=0,bTrader=True,Song="KF_Defection",Artist="zYnthetic",Title="Defection")
    MyMusic( 1)=(PL=1,Wave=0,bTrader=True,Song="KF_Harm",Artist="zYnthetic",Title="Harm Intended")
    MyMusic( 2)=(PL=1,Wave=0,bTrader=True,Song="KF_Insect",Artist="zYnthetic",Title="Insect Wings")
    MyMusic( 3)=(PL=1,Wave=0,bTrader=True,Song="KF_Mutagen",Artist="zYnthetic",Title="Mutagen")
    MyMusic( 4)=(PL=1,Wave=0,bTrader=True,Song="KF_Neurotoxin",Artist="zYnthetic",Title="Neurotoxin")
    MyMusic( 5)=(PL=1,Wave=0,bTrader=True,Song="KF_Peripheral",Artist="zYnthetic",Title="Peripheral")
    MyMusic( 6)=(PL=1,Wave=0,bTrader=True,Song="KF_SinSoma",Artist="zYnthetic",Title="Sin Soma and the Masquerade")
    MyMusic( 7)=(PL=1,Wave=0,bTrader=True,Song="KF_Smolder",Artist="zYnthetic",Title="Smolder")
    MyMusic( 8)=(PL=1,Wave=0,bTrader=True,Song="KF_SurfaceTension",Artist="zYnthetic",Title="Surface Tension")
    MyMusic( 9)=(PL=1,Wave=0,bTrader=True,Song="KF_TheEdge",Artist="zYnthetic",Title="The Edge Of The Abyss")
    MyMusic(10)=(PL=1,Wave=0,bTrader=True,Song="KF_TheStitches",Artist="zYnthetic",Title="The Stitches Are A Reminder")
    MyMusic(11)=(PL=1,Wave=0,bTrader=True,Song="KF_Treatments",Artist="zYnthetic",Title="Treatments Are More Profitable Than Cures")
    MyMusic(12)=(PL=1,Wave=0,bTrader=True,Song="KF_Vapour",Artist="zYnthetic",Title="Vapour")
    MyMusic(13)=(PL=1,Wave=0,bTrader=True,Song="KF_Wading",Artist="zYnthetic",Title="Wading Through The Bodies")
    MyMusic(14)=(PL=1,Wave=0,Song="DirgeDefective1",Artist="Dirge",Title="Defective")
    MyMusic(15)=(PL=1,Wave=0,Song="DirgeDefective2",Artist="Dirge",Title="Defective")
    MyMusic(16)=(PL=1,Wave=0,Song="DirgeDisunion1",Artist="Dirge",Title="Disunion")
    MyMusic(17)=(PL=1,Wave=0,Song="DirgeDisunion2",Artist="Dirge",Title="Disunion")
    MyMusic(18)=(PL=1,Wave=0,Song="DirgeRepulse1",Artist="Dirge",Title="Repulse")
    MyMusic(19)=(PL=1,Wave=0,Song="DirgeRepulse2",Artist="Dirge",Title="Repulse")
    MyMusic(20)=(PL=1,Wave=0,Song="KF_Infectious_Cadaver",Artist="Six Feet of Foreplay",Title="Infectious Cadaver")
    MyMusic(21)=(PL=1,Wave=0,Song="KF_BledDry",Artist="zYnthetic",Title="Bled Dry")
    MyMusic(22)=(PL=1,Wave=0,Song="KF_Containment",Artist="zYnthetic",Title="Containment Breach")
    MyMusic(23)=(PL=1,Wave=0,Song="KF_Hunger",Artist="zYnthetic",Title="Hunger")
    MyMusic(24)=(PL=1,Wave=0,Song="KF_Pathogen",Artist="zYnthetic",Title="Pathogen")
    MyMusic(25)=(PL=1,Wave=0,Song="KF_WPrevention",Artist="zYnthetic",Title="Witness Prevention")
    MyMusic(26)=(PL=1,Wave=11,Song="KF_Abandon",Artist="zYnthetic",Title="Abandon All")

    MyMusic(27)=(PL=2,Wave=0,bTrader=True,Song="EGT-ThisLove",Artist="elguitarTom",Title="Waiting For Romero To Play")
    MyMusic(28)=(PL=2,Wave=0,bTrader=True,Song="EGT-Interlevel",Artist="elguitarTom",Title="Interlevel")
    MyMusic(29)=(PL=2,Wave=1,Song="EGT-Entryway",Artist="elguitarTom",Title="Entryway")
    MyMusic(30)=(PL=2,Wave=2,Song="EGT-E1M1",Artist="elguitarTom",Title="E1M1")
    MyMusic(31)=(PL=2,Wave=3,Song="EGT-Demon1",Artist="elguitarTom",Title="The Demon's Dead, Part 1")
    MyMusic(32)=(PL=2,Wave=4,Song="EGT-Shawn",Artist="elguitarTom",Title="Shawn's Got The Shotgun")
    MyMusic(33)=(PL=2,Wave=5,Song="EGT-ToxinRefinery",Artist="elguitarTom",Title="Toxin Refinery")
    MyMusic(34)=(PL=2,Wave=6,Song="EGT-Entryway",Artist="elguitarTom",Title="Entryway")
    MyMusic(35)=(PL=2,Wave=7,Song="EGT-Demon2",Artist="elguitarTom",Title="The Demon's Dead, Part 2")
    MyMusic(36)=(PL=2,Wave=8,Song="EGT-PhobosLab",Artist="elguitarTom",Title="Phobos Lab")
    MyMusic(37)=(PL=2,Wave=9,Song="EGT-E1M1",Artist="elguitarTom",Title="E1M1")
    MyMusic(38)=(PL=2,Wave=10,Song="EGT-Shawn",Artist="elguitarTom",Title="Shawn's Got The Shotgun")
    MyMusic(39)=(PL=2,Wave=11,Song="EGT-SignOfEvil",Artist="elguitarTom",Title="Sign Of Evil")

    // TSC
    RedCharacter="Pyro_Red"
    BlueCharacter="Pyro_Blue"
    bNotifyLocalPlayerTeamReceived=True
    bTSCAutoDetectKeys=true

    RedCharacters(0)="Pyro_Red"
    RedCharacters(1)="Agent_Wilkes"
    RedCharacters(2)="Ash_Harding"
    RedCharacters(3)="Chopper_Harris"
    RedCharacters(4)="Corporal_Lewis"
    RedCharacters(5)="Dave_The_Butcher_Roberts"
    RedCharacters(6)="DJ_Scully"
    RedCharacters(7)="Dr_Gary_Glover"
    RedCharacters(8)="FoundryWorker_Aldridge"
    RedCharacters(9)="Harold_Hunt"
    RedCharacters(10)="Harold_Lott"
    RedCharacters(11)="Kerry_Fitzpatrick"
    RedCharacters(12)="Kevo_Chav"
    RedCharacters(13)="KF_Soviet"
    RedCharacters(14)="Lieutenant_Masterson"
    RedCharacters(15)="Mrs_Foster"
    RedCharacters(16)="Mr_Foster"
    RedCharacters(17)="Paramedic_Alfred_Anderson"
    RedCharacters(18)="Police_Constable_Briar"
    RedCharacters(19)="Police_Sergeant_Davin"
    RedCharacters(20)="Private_Schnieder"
    RedCharacters(21)="Reverend_Alberts"
    RedCharacters(22)="Ricky_Vegas"
    RedCharacters(23)="Samuel_Avalon"
    RedCharacters(24)="Security_Officer_Thorne"
    RedCharacters(25)="Sergeant_Powers"
    RedCharacters(26)="Shadow_Ferret"
    RedCharacters(27)="Trooper_Clive_Jenkins"
    RedCharacters(28)="Mr_Magma"
    RedCharacters(29)="Ms_Clamley"

    BlueCharacters(0)="Pyro_Blue"
    BlueCharacters(1)="Baddest_Santa"
    BlueCharacters(2)="Captian_Wiggins"
    BlueCharacters(3)="ChickenNator"
    BlueCharacters(4)="Commando_Chicken"
    BlueCharacters(5)="Dr_Jeffrey_Tamm"
    BlueCharacters(6)="DAR"
    BlueCharacters(7)="Harchier_Spebbington"
    BlueCharacters(8)="Harchier_Spebbington_II"
    BlueCharacters(9)="Hayato_Tanaka"
    BlueCharacters(10)="KF_German"
    BlueCharacters(11)="LanceCorporal_Lee_Baron"
    BlueCharacters(12)="Mike_Noble"
    BlueCharacters(13)="Reaper"
    BlueCharacters(14)="Reggie"
    BlueCharacters(15)="Steampunk_Berserker"
    BlueCharacters(16)="Steampunk_Commando"
    BlueCharacters(17)="Steampunk_Demolition"
    BlueCharacters(18)="Steampunk_DJ_Scully"
    BlueCharacters(19)="Steampunk_Firebug"
    BlueCharacters(20)="Steampunk_Medic"
    BlueCharacters(21)="Steampunk_MrFoster"
    BlueCharacters(22)="Steampunk_Mrs_Foster"
    BlueCharacters(23)="Steampunk_Sharpshooter"
    BlueCharacters(24)="Steampunk_Support_Specialist"
    BlueCharacters(25)="Voltage"
}
