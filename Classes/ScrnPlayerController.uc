/* CODE BREAKING WARNING in v5.16 Beta 12 
Removed AchInfo objects. Used AchDef.CurrentProgress instead

Changed variables and functions:
+ AchStrInfo
! PendingAchievements
- CurrentAchievement
+ CurrentAchHandler, CurrentAchIndex;
! DisplayAchievementStatus(), DisplayCurrentAchievement(), PlayerTick()

ScrnAchievementEarnedMsg - requires ScrnAchievement object to be passed as optional object, switch now indicates ach index

*/


class ScrnPlayerController extends KFPCServ;

var byte VeterancyChangeWave; // wave number, when player has changed his perk 

var globalconfig bool bManualReload, bOtherPlayerLasersBlue;
var globalconfig bool bAlwaysDisplayAchProgression; // always display a message on any achievement progress
var globalconfig int AchGroupIndex;

var globalconfig bool bSpeechVote; //allow using speeches Yes and No in voting

var ScrnBalance Mut;


var transient array<ScrnAchievements.AchStrInfo>PendingAchievements; //earned achievements waiting to be displayed on the HUD
//current achievement object and index to display on the HUD
var transient ScrnAchievements CurrentAchHandler; 
var transient int CurrentAchIndex;

var float AchievementDisplayCooldown; // time to wait between displaying achievements, if multiple achievements were earned

var transient class<KFVeterancyTypes> InitialPerkClass;
var bool bChangedPerkDuringGame; // player changed his perk during a game 
var transient bool bCowboyForWave;
var transient byte BeggingForMoney; // how many times player asked for money during this wave

var byte MaxVoiceMsgIn10s; // maximum number of voice messages during 10 seconds
var bool bZEDTimeActive;

var bool bHadArmor; //player had armor during the game

var bool bWeaponsLocked; // disables player's weapons pick up by other players
var localized string strLocked, strUnlocked, strLockDisabled;
var transient float LastLockMsgTime; // last time when player received a message that weapon is locked

var localized string strAlreadySpectating;

var globalconfig bool bPrioritizePerkedWeapons;

var int StartCash; // amount of cash given to this pawn on game/wave start

var private transient bool bHadPawn;

struct SDualWieldable {
	var class<KFWeapon> Single, Dual;
};
var array<SDualWieldable> DualWieldables;
var private transient bool bDualWieldablesLoaded;


// TSC
var string ProfilePageClassString;
var	string	TSCLobbyMenuClassString;
var config bool bTSCAdvancedKeyBindings; // pressing altfire while carrying the guardian gnome, sets up the base
var config string RedCharacter, BlueCharacter;
var localized string strCantShopInEnemyTrader;

// not replicated yet
// todo: find an efficient way to replicate 
var array<string> RedCharacters, BlueCharacters;

var class<ScrnCustomPRI> CustomPlayerReplicationInfoClass;
var transient bool bDestroying; // indicates that Destroyed() is executing

var bool bDamageAck; // does server needs to acknowledge client of damages he made?

var transient byte PerkChangeWave; // wave num, when perk was changed last time

var transient Controller FavoriteSpecs[2];
var localized string strSpecFavoriteAssigned, strSpecNoFavorites;
var transient Actor OldViewTarget;

var transient rotator PrevRot;
var transient int ab_warning;


replication
{
    reliable if ( Role == ROLE_Authority )
        ClientMonsterBlamed;

    unreliable if ( bDamageAck && Role == ROLE_Authority )
        ClientPlayerDamaged;

    reliable if ( Role < ROLE_Authority )
        ServerVeterancyLevelEarned, ResetMyAchievements, ResetMapAch,
		ServerDropAllWeapons, ServerLockWeapons,
        ServerAcknowledgeDamages,
        ServerDebugRepLink,
        ServerTourneyCheck, ServerKillMut, ServerKillRules,
        ServerSwitchViewMode, ServerSetViewTarget;
	
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


simulated function LoadMutSettings()
{
    if ( Mut != none ) {
        if ( Mut.bForceManualReload)
            bManualReload = Mut.bManualReload;
        if ( Mut.bHardCore )
            bOtherPlayerLasersBlue = false;
    }
    else { 
        //this shouldn't happen
        log("Player Controller can not find ScrnBalance!", class.outer.name);
        if ( class'ScrnBalance'.default.bForceManualReload)
            bManualReload =  class'ScrnBalance'.default.bManualReload;
        if ( class'ScrnBalance'.default.Mut.bHardcore )
            bOtherPlayerLasersBlue = false;        
    }
}

function InitPlayerReplicationInfo()
{
    local LinkedReplicationInfo L;
    local ScrnCustomPRI ScrnPRI;
    
    super.InitPlayerReplicationInfo();
    
    for( L=PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo ) {
        if ( ScrnCustomPRI(L) != none )
            return; // wtf?
        if( L.NextReplicationInfo==None )
            break;    
    }
    
    ScrnPRI = spawn(CustomPlayerReplicationInfoClass, self); 
    if ( L == none )
        PlayerReplicationInfo.CustomReplicationInfo = ScrnPRI;
    else
        L.NextReplicationInfo = ScrnPRI;
}

final static function ScrnCustomPRI FindScrnCustomPRI(PlayerReplicationInfo PRI)
{
    local LinkedReplicationInfo L;
    local ScrnCustomPRI result;
    
    for( L = PRI.CustomReplicationInfo; L != none && result == none ; L = L.NextReplicationInfo )
        result = ScrnCustomPRI(L);
    
    return result;
}

/* 
// NOW INTEGRATED INTO Marco's SP v6.50

simulated function PreloadFireModeAssets(class<WeaponFire> WF)
{
    local class<Projectile> P;//log("ScrnPlayerController.PreloadFireModeAssets()" @ WF, default.class.outer.name);

    if ( WF == none || WF == Class'KFMod.NoFire' ) 
        return;


    if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
        class<KFFire>(WF).static.PreloadAssets(Level);
    else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
        class<KFMeleeFire>(WF).static.PreloadAssets();
    else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
        class<KFShotgunFire>(WF).static.PreloadAssets(Level);

        
    // preload projectile assets    
    P = WF.default.ProjectileClass;
    //log("Projectile =" @ P, default.class.outer.name);
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
}

simulated function UnloadFireModeAssets(class<WeaponFire> WF)
{
    local class<Projectile> P;

    if ( WF == none || WF == Class'KFMod.NoFire' ) 
        return;

    if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
        class<KFFire>(WF).static.UnloadAssets();
    else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
        class<KFMeleeFire>(WF).static.UnloadAssets();
    else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
        class<KFShotgunFire>(WF).static.UnloadAssets();
        
    // Unload projectile assets only if refs aren't empty (i.e. they have been dynamically loaded)    
    P = WF.default.ProjectileClass;
    if ( P == none || P.default.StaticMesh != none ) 
        return;
        
    if ( class<ScrnCustomShotgunBullet>(P) != none )
        class<ScrnCustomShotgunBullet>(P).static.UnloadAssets();               
    else if ( class<CrossbuzzsawBlade>(P) != none )
        class<CrossbuzzsawBlade>(P).static.UnloadAssets();               
    else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
        class<LAWProj>(P).static.UnloadAssets();               
    else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
        class<M79GrenadeProjectile>(P).static.UnloadAssets();               
    else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
        class<SPGrenadeProjectile>(P).static.UnloadAssets();               
    else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
        class<HealingProjectile>(P).static.UnloadAssets();               
    else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
        class<CrossbowArrow>(P).static.UnloadAssets();   
    else if ( class<M99Bullet>(P) != none )
        class<M99Bullet>(P).static.UnloadAssets();               
    else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
        class<PipeBombProjectile>(P).static.UnloadAssets();               
}

simulated function ClientWeaponSpawned(class<Weapon> WClass, Inventory Inv)
{
    local class<KFWeapon> W;
    local class<KFWeaponAttachment> Att;
    
    //log("ScrnPlayerController.ClientWeaponSpawned()" @ WClass $ ". Default Mesh = " $ WClass.default.Mesh, default.class.outer.name);
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
        PreloadFireModeAssets(W.default.FireModeClass[0]);
        PreloadFireModeAssets(W.default.FireModeClass[1]);
    }
}

simulated function ClientWeaponDestroyed(class<Weapon> WClass)
{
    local class<KFWeapon> W;
    local class<KFWeaponAttachment> Att;
    
    //log(default.class @ "ClientWeaponDestroyed()" @ WClass, default.class.outer.name);
    //super.ClientWeaponDestroyed(WClass); 
    
    W = class<KFWeapon>(WClass);
    //if default mesh is set, then count that weapon has static assets, so don't unload them
    // that's lame, but no so lame as Tripwire's original code
    if ( W != none && W.default.MeshRef != "" && W.static.UnloadAssets() ) {
        Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
        if ( Att != none && Att.default.Mesh == none )
            Att.static.PreloadAssets();
        UnloadFireModeAssets(W.default.FireModeClass[0]);
        UnloadFireModeAssets(W.default.FireModeClass[1]);
    }
}
*/



/*
function AcknowledgePossession(Pawn P)
{
    // make sure old pawn controller is right
    if ( Pawn != AcknowledgedPawn ) {
        if( ScrnHumanPawn(AcknowledgedPawn) != none ) 
            ScrnHumanPawn(AcknowledgedPawn).ScrnPlayer = none;
    }
    if( ScrnHumanPawn(P) != none )  {
        ScrnHumanPawn(P).ScrnPlayer = self;
    }

    super.AcknowledgePossession(P);
}

function ServerAcknowledgePossession(Pawn P, float NewHand, bool bNewAutoTaunt)
{
    // make sure old pawn controller is right
    if ( Pawn != AcknowledgedPawn ) {
        if( ScrnHumanPawn(AcknowledgedPawn) != none ) 
            ScrnHumanPawn(AcknowledgedPawn).ScrnPlayer = none;
    }
    if( ScrnHumanPawn(P) != none )  {
        ScrnHumanPawn(P).ScrnPlayer = self;
    }
    
    super.ServerAcknowledgePossession(P, NewHand, bNewAutoTaunt);
}

function UnPossess()
{
    super.UnPossess();
    Mut.GameRules.CheckPlayersAlive();
}


*/

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
    if ( ScrnHumanPawn(Pawn) != none )
        ScrnHumanPawn(Pawn).CookGrenade();
}

exec function ThrowCookedGrenade()
{
    if ( ScrnHumanPawn(Pawn) != none )
        ScrnHumanPawn(Pawn).ThrowCookedGrenade();
}

/** 
 * DamTypeNum:
 * 0 - normal
 * 1 - headshot
 * 2 - fire DoT
 */
function DamageMade(int Damage, vector HitLocation, byte DamTypeNum)
{
    local ScrnPlayerController ScrnPC;
    local int i;
    
    ClientPlayerDamaged(Damage, HitLocation, DamTypeNum);
    
    if ( Role == ROLE_Authority && ScrnHumanPawn(Pawn) != none && ScrnHumanPawn(Pawn).bViewTarget ) {
        // show damage popups on spectating players
        for ( i=0; i<Level.GRI.PRIArray.length; ++i ) {
            if ( Level.GRI.PRIArray[i] != none && Level.GRI.PRIArray[i].bOnlySpectator ) {
                ScrnPC = ScrnPlayerController(Level.GRI.PRIArray[i].Owner);
                if ( ScrnPC != none && ScrnPC != self && ScrnPC.ViewTarget == Pawn )
                    ScrnPC.ClientPlayerDamaged(Damage, HitLocation, DamTypeNum);
            }
        }
    }
}

simulated function ClientPlayerDamaged(int Damage, vector HitLocation, byte DamTypeNum)
{
    local ScrnHUD hud;
    
    hud = ScrnHUD(myHUD);
    if ( hud != none ) {
        if ( hud.bShowDamages )
            hud.ShowDamage(Damage, Level.TimeSeconds, HitLocation, DamTypeNum);
        else
            ServerAcknowledgeDamages(false); // tell server we don't need damage acks            
    }
}

function ServerAcknowledgeDamages(bool bWantDagage)
{
    bDamageAck = bWantDagage;    
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

exec function TogglePlayerInfo()
{
    if ( ScrnHUD(myHUD) != none )
        ScrnHUD(myHUD).bHidePlayerInfo = !ScrnHUD(myHUD).bHidePlayerInfo; 
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
    
    //log("Player Controller Tick", class.outer.name);
    if ( Viewport(Player) != None ) {
        AchievementDisplayCooldown -= DeltaTime;
        if ( PendingAchievements.Length > 0 && AchievementDisplayCooldown <= 0 ) {
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
    //log("DisplayCurrentAchievement:" @CurrentAchievement.ID @ CurrentAchievement.CurrentProgress$"/"$ CurrentAchievement.MaxProgress ,class.outer.name);
    if ( CurrentAchHandler != none ) {
        if ( CurrentAchHandler.AchDefs[CurrentAchIndex].bUnlockedJustNow ) {
            //set cooldown only for earned achievements. Status updates can be immediately overrided 
            AchievementDisplayCooldown = default.AchievementDisplayCooldown; 
            ClientPlaySound(Sound'KF_InterfaceSnd.Perks.PerkAchieved',true,2.f,SLOT_Talk);
            ClientPlaySound(Sound'KF_InterfaceSnd.Perks.PerkAchieved',true,2.f,SLOT_Interface);
        } 
        else {
            AchievementDisplayCooldown = fmax(0, AchievementDisplayCooldown);
        }
        CurrentAchHandler.AchDefs[CurrentAchIndex].bUnlockedJustNow = false;
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
            ConsoleMessage(Class'ScrnAchievementEarnedMsg'.default.EarnedString $ ": " $ AchHandler.AchDefs[AchIndex].DisplayName, 0, 1, 200, 1);

        if ( PendingAchievements.Length == 0 && AchievementDisplayCooldown <= 0 ) {
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
        log(S, class.outer.name);
        Type = '';
    }
        
    if ( Mut != none )
        super.ClientMessage(Mut.ParseColorTags(S), Type);
    else    
        super.ClientMessage(S, Type);
}

function LongMessage(string S, optional int MaxLen, optional string Divider)
{
    class'ScrnBalance'.static.LongMessage(self, S, MaxLen, Divider);
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

        if ( (Player != None) && (Player.Console != None) )
	{
		if ( PRI!=None )
		{
			if ( PRI.Team!=None && GameReplicationInfo.bTeamGame)
			{
    			if (PRI.Team.TeamIndex==0)
					c = chr(27)$chr(200)$chr(1)$chr(1);
    			else if (PRI.Team.TeamIndex==1)
        			c = chr(27)$chr(75)$chr(139)$chr(198);
			}
			S = Mut.ColoredPlayerName(PRI)$c$": "$ Mut.ParseColorTags(S);
		}
		Player.Console.Chat( c$s, 6.0, PRI );
	}
}

function ServerVeterancyLevelEarned()
{
    if ( ScrnHumanPawn(Pawn) != none )
        ScrnHumanPawn(Pawn).VeterancyChanged();
}


simulated function ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	if ( Message == class'KFVetEarnedMessageSR' ) {
		// I didn't found any better way to track perk leveling up
    	super.ReceiveLocalizedMessage(class'KFVetEarnedMessageScrn', Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
		ServerVeterancyLevelEarned();
	}
	else {
        if ( Switch == 1 && Message == class'TSCSharedMessages' )
            ClientCloseMenu(true, true); // trying to shop in enemy trader
        
    	super.ReceiveLocalizedMessage(Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    }
}

function ResetWaveStats()
{
	local KFPlayerReplicationInfo KFPRI;
	
	KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	
    bCowboyForWave = true;
	BeggingForMoney = 0;
	bHadArmor = bHadArmor || (KFPRI != none	&& KFPRI.ClientVeteranSkill != none 
		&& KFPRI.ClientVeteranSkill.static.ReduceDamage(KFPRI, KFPawn(Pawn), none, 100, none) < 100);
    
    if ( ScrnHumanPawn(Pawn) != none )
        ScrnHumanPawn(Pawn).ApplyWeaponStats(Pawn.Weapon);
}

exec function ResetMyAchievements(string group)
{
    class'ScrnAchievements'.static.ResetAchievements(SRStatsBase(SteamStatsAndAchievements).Rep, group);     
}

exec function ResetMapAch(string MapName)
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;
    local ScrnMapAchievements A;
    local int i, j;
    
    L = SRStatsBase(SteamStatsAndAchievements).Rep;
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


exec function MVote(string VoteString)
{
    ServerMutate("VOTE " $ VoteString);
}

exec function MVB(string Params)
{
    ServerMutate("VOTE BLAME " $ Params);
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
    if ( ScrnHumanPawn(Pawn) != none )
        ConsoleMessage(String(ScrnHumanPawn(Pawn).IsMedic()));
}

// overrided to call vote for pause in unable to pause directly
function bool SetPause( BOOL bPause )
{
    bFire = 0;
    bAltFire = 0;
    if ( !Level.Game.SetPause(bPause, self) ) {
        ServerMutate("VOTE PAUSE 60");
        return false;
    }
    return true;
}

function BecomeSpectator()
{
    super.BecomeSpectator();
    
	if (Role < ROLE_Authority)
		return;

    if ( Mut.bDynamicLevelCap && Mut.KF.bTradingDoorsOpen )
        Mut.DynamicLevelCap();     
}
        
function BecomeActivePlayer()
{
    super.BecomeActivePlayer();
    
	if (Role < ROLE_Authority)
		return;
    
	if ( !PlayerReplicationInfo.bOnlySpectator ) {
		if ( Mut.KF.bTradingDoorsOpen ) {
			if ( Mut.bDynamicLevelCap )
				Mut.DynamicLevelCap();    
		}
		StartCash = PlayerReplicationInfo.Score;
	}
}

function Possess(Pawn aPawn)
{
	//ClientMessage("Possess("$aPawn$"). Current Pawn="$Pawn);
	if ( Role == ROLE_Authority && Mut != none ) {
		if ( bHadPawn )
			StartCash = max(StartCash, Mut.KF.MinRespawnCash);
		else
			StartCash = max(StartCash, Mut.KF.StartingCash);
            
	}
    
	super.Possess(aPawn);
    
	bHadPawn = bHadPawn || Pawn != none;
}

simulated event Destroyed()
{
    bDestroying = true;
    
    if ( ScrnHumanPawn(Pawn) != none )
        ScrnHumanPawn(Pawn).HealthBeforeDeath = Pawn.Health;
        
    if ( Level.NetMode != NM_DedicatedServer && Level.GetLocalPlayerController() == self )
        RemoveVotingMsg(); // delete voting interactions
        
    if ( Role == ROLE_Authority ) {   
        if ( Mut != none && Mut.bLeaveCashOnDisconnect && PlayerReplicationInfo != none && PlayerReplicationInfo.Team != none 
                && PlayerReplicationInfo.Score > StartCash ) 
        {
            PlayerReplicationInfo.Team.Score += PlayerReplicationInfo.Score - StartCash;
            PlayerReplicationInfo.Score = StartCash; // just in case
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

exec function RemoveVotingMsg()
{
    local VHInteraction RemoveMe;

    foreach AllObjects(class'VHInteraction', RemoveMe) {
        RemoveMe.Master.RemoveInteraction(RemoveMe);
    }
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


exec function Ready() 
{
	if ( PlayerReplicationInfo.bOnlySpectator )	
		BecomeActivePlayer();

	if ( PlayerReplicationInfo.Team == none || Level.GRI.bMatchHasBegun ) 
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
    if ( TSCGameReplicationInfoBase(Level.GRI) != none )
        ClientOpenMenu(TSCLobbyMenuClassString);
    else
        ClientOpenMenu(LobbyMenuClassString);
}

 
function LoadDualWieldables()
{
	local ClientPerkRepLink CPRL;
	local class<KFWeaponPickup> WP;
	local class<KFWeapon> W;
	local int i;
	
	CPRL = SRStatsBase(SteamStatsAndAchievements).Rep;
	if( CPRL==None || CPRL.ShopInventory.Length == 0 )
		return; // Hmmmm?	
		
		
	for ( i=0; i<CPRL.ShopInventory.Length; ++i ) {
		WP = class<KFWeaponPickup>(CPRL.ShopInventory[i].PC);
		if ( WP == none )
			continue;
		W = class<KFWeapon>(WP.default.InventoryType);
		if ( W != none && W.Default.DemoReplacement != none )
			AddDualWieldable(class<KFWeapon>(W.Default.DemoReplacement), W);
	}
	
	bDualWieldablesLoaded = !CPRL.IsInState('RepSetup');
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
        
    if ( !bTSCAdvancedKeyBindings && PlayerReplicationInfo.HasFlag != none 
            && GameObject(PlayerReplicationInfo.HasFlag) != none 
            && TSCGameReplicationInfoBase(Level.GRI) != none )  {
        ServerScoreFlag();
        return;
    }
    
    super.AltFire(F);
}

function ServerThrowWeapon()
{
    if ( !bTSCAdvancedKeyBindings && GameObject(PlayerReplicationInfo.HasFlag) != none )
        ServerDropFlag();
    else
	    super.ServerThrowWeapon();
}

// character selection
simulated function bool IsTeamCharacter(string CharacterName)
{
    if ( CharacterName == "" )
        return false;
        
    if ( TSCGameReplicationInfoBase(Level.GRI) == none || PlayerReplicationInfo == none || PlayerReplicationInfo.Team == none )
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

// bypass KFPCServ to avoid calling FindStats() on server side
exec function ChangeCharacter(string newCharacter, optional string inClass)
{
    local ClientPerkRepLink L;
    
    if ( newCharacter == "" || !IsTeamCharacter(newCharacter) )
        return;
       
    if ( SRStatsBase(SteamStatsAndAchievements) != none ) 
        L = SRStatsBase(SteamStatsAndAchievements).Rep;
        
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
    local ClientPerkRepLink L;
    
	if( SRStatsBase(SteamStatsAndAchievements)!=none )
        L = SRStatsBase(SteamStatsAndAchievements).Rep;
        
    if ( L != none ) {
        if ( ScrnClientPerkRepLink(L) != none )
            ScrnClientPerkRepLink(L).ServerSelectPerkSE(Class<SRVeterancyTypes>(VetSkill));
        else
            L.ServerSelectPerk(Class<SRVeterancyTypes>(VetSkill));
    }
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

    ClientMessage(string(Level.Game.class));
    
    GT = ScrnGameType(Level.Game);
    if ( GT == none )
        ClientMessage("Current game type doesn't support Tourney Mode");
    else {
        ClientMessage("Tourney Mode: " $ GT.IsTourney());
        //LongMessage("Command Line: " $ GT.GetCmdLine(), 80, "?");
    }
    
    s = "Mutators:";
    for ( M = Level.Game.BaseMutator; M != None; M = M.NextMutator ) {
        if ( len(s) > 80) {
            ClientMessage(s);
            s = "";
        }
        s @= string(M.class);
    }
    LongMessage(s, 80, " ");
    
    s = "Rules:";
    for ( G=Level.Game.GameRulesModifiers; G!=None; G=G.NextGameRules ) {
        if ( len(s) > 80) {
            ClientMessage(s);
            s = "";
        }
        s @= string(G.class);
    }
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


// STATES

state Dead
{
    // fix of null-reference
    function Timer()
	{
        if ( KFStoryGameInfo(Level.Game) != none )
            super.Timer();
        else
            super(KFPlayerController).Timer(); // bypass KFPlayerController_Story
    }
}

function ServerViewNextPlayer()
{
    super.ServerViewNextPlayer();
    ViewTargetChanged();
}

function ServerViewSelf()
{
    super.ServerViewSelf();
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

    if ( !IsInState('Spectating') || !PlayerReplicationInfo.bOnlySpectator )
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
    
    if ( Role < ROLE_Authority || !PlayerReplicationInfo.bOnlySpectator )
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
}


state Spectating
{
    exec function SwitchWeapon(byte T) 
    {
        ServerSwitchViewMode(T);
    } 
    
    exec function Use()
    {
        local vector HitLocation, HitNormal, TraceEnd, TraceStart;
        local rotator R;
        local Actor A;
        
        if( !PlayerReplicationInfo.bOnlySpectator )
            return;

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
    
    c = class'ScrnBalance'.default.Mut.ParseColorTags(ColorTagString);
    s = class'ScrnBalance'.default.Mut.StripColorTags(ColorTagString);
    if ( i > 0) {
        c = class'ScrnBalance'.static.LeftCol(c, i);
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
        ClientMessage("My Team Index = " $ PlayerReplicationInfo.Team.TeamIndex);
}


function DebugRepLink(string S)
{
    local ClientPerkRepLink L;
    local ScrnClientPerkRepLink SL;
    
    if ( Role < ROLE_Authority ) {
        L = class'ClientPerkRepLink'.static.FindStats(self);
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



// ======================== COMMENT BEFORE RELEASE !!! =====================


/*
exec function PerkLevel(int level)
{
    if ( Level.NetMode != NM_Standalone )
        return;    
        
    KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkillLevel = level;
} 

exec function PawnNames()
{
	local Controller C;
	
	for ( C=Level.ControllerList; C!=none; C=C.NextController ) {
		if ( C.Pawn != none )
			ClientMessage("The name of" @ String(C.Pawn.class) @ "is" @ C.Pawn.name);
	}
}

exec function GiveSpawnInv()
{
	if ( Role != ROLE_Authority )
		return;
	
	KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.AddDefaultInventory(KFPlayerReplicationInfo(PlayerReplicationInfo), Pawn);
}


exec function MonsterInfo(float angle)
{
	local ScrnPlayerInfo SPI;
	
	SPI = Mut.GameRules.GetPlayerInfo(self);
	if ( SPI == none ) {	
		ClientMessage("No player info found");
		return;
	}
	ClientMessage("Last damaged monster = " $GetItemName(String(SPI.LastDamagedMonster))
		$". Can be seen = " $ CanSee(SPI.LastDamagedMonster)
		$". Can see me = " $ SPI.LastDamagedMonster.Controller.CanSee(Pawn)
		$". I'm in Line of sight = " $ SPI.LastDamagedMonster.Controller.LineOfSightTo(Pawn)
		$". I'm rotated at monster = " $ class'ScrnAchHandlerBase'.static.IsRotatedAtLocation(Pawn, SPI.LastDamagedMonster.Location, angle)
		);
}


exec function TestWaveSize(int PlayerCount) 
{
	Mut.KF.TotalMaxMonsters = 10000;
	Mut.GameRules.PlayersAlive.Length = PlayerCount;
	Mut.KF.NumBots = 0;
	Mut.GameRules.SetupWaveSize();
}


exec function TestEndGame()
{
    Mut.GameRules.bSuperPat = true; 
    Mut.GameRules.DoomHardcorePointsGained = 6;
    Mut.GameRules.HardcoreLevel = 15;
    Mut.KF.WaveNum = Mut.KF.FinalWave + 1;
    Mut.KF.CheckEndGame(PlayerReplicationInfo, "Test");
}

exec function GiveShields(int value)
{
    local xPawn P;
    
    foreach DynamicActors(class'xPawn', P) {
        P.ShieldStrength = value;  
        P.ShieldStrengthMax = max(value, 100);  
    }
}

exec function SpamPickups()
{
    local NavigationPoint N;
    local int i, c;
    local ClientPerkRepLink L;
    
    L = SRStatsBase(SteamStatsAndAchievements).Rep;
    for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint ) {
        for ( i = 0; i < L.ShopInventory.Length; ++i ) {
            spawn(L.ShopInventory[i].PC, N, '', N.Location);
            c++;
        }
    }
    ConsoleMessage("Spawned pickup count = " $ string(c));
}
exec function FreePickups()
{
    local NavigationPoint N;
    local Pickup P;
    
    for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint ) {
        foreach N.ChildActors(class'Pickup', P) {
            P.Destroy();
        }
    }
}
*/






defaultproperties
{
    bManualReload=True
    bDamageAck=True
    AchievementDisplayCooldown=5.000000
    bChangedPerkDuringGame=True
    ProfilePageClassString="ScrnBalanceSrv.ScrnProfilePage"
    LobbyMenuClassString="ScrnBalanceSrv.ScrnLobbyMenu"
    TSCLobbyMenuClassString="TSC.TSCLobbyMenu"
    PawnClass=Class'ScrnBalanceSrv.ScrnHumanPawn'
    CustomPlayerReplicationInfoClass=class'ScrnBalanceSrv.ScrnCustomPRI'
    bSpeechVote=true
	bAlwaysDisplayAchProgression=true
	MaxVoiceMsgIn10s=5
	strLocked="Weapon pickups LOCKED"
	strUnlocked="Weapon pickups UNLOCKED"
	strLockDisabled="Weapon lock is disabled by server"
	strAlreadySpectating="Already spectating. Type READY, if you want to join the game."
	
	DualWieldables(0)=(Single=class'KFMod.Single',Dual=class'KFMod.Dualies')
	DualWieldables(1)=(Single=class'KFMod.Deagle',Dual=class'KFMod.DualDeagle')
	DualWieldables(2)=(Single=class'KFMod.GoldenDeagle',Dual=class'KFMod.GoldenDualDeagle')
	DualWieldables(3)=(Single=class'KFMod.Magnum44Pistol',Dual=class'KFMod.Dual44Magnum')
	DualWieldables(4)=(Single=class'KFMod.MK23Pistol',Dual=class'KFMod.DualMK23Pistol')
	DualWieldables(5)=(Single=class'KFMod.FlareRevolver',Dual=class'KFMod.DualFlareRevolver')
    
    strSpecFavoriteAssigned="View target marked as favorite"
    strSpecNoFavorites="No favorite view targets! Press '4' to assign favorite."
    
    // TSC
    strCantShopInEnemyTrader="You can not trade with enemy trader!"
    RedCharacter="Pyro_Red"
    BlueCharacter="Pyro_Blue"
    bNotifyLocalPlayerTeamReceived=True
    
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
