class ScrnM7A3MMedicGun extends M7A3MMedicGun;

var         name             ReloadShortAnim;
var         float             ReloadShortRate;

var transient bool bShortReload;
var transient bool bWasFullyCharged;

// copy-pasted to add (MagCapacity+1)
simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if( !Instigator.IsHumanControlled() ) {
        return !bIsReloading && MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining;
    }

    return !( FireMode[0].IsFiring() || FireMode[1].IsFiring() || bIsReloading || ClientState == WS_BringUp
            || MagAmmoRemaining >= MagCapacity + 1 || AmmoAmount(0) <= MagAmmoRemaining
            || (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 );
}

exec function ReloadMeNow()
{
    local float ReloadMulti;

    if(!AllowReload())
        return;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    ReloadTimer = Level.TimeSeconds;
    bShortReload = MagAmmoRemaining > 0;
    if ( bShortReload )
        ReloadRate = Default.ReloadShortRate / ReloadMulti;
    else
        ReloadRate = Default.ReloadRate / ReloadMulti;

    if( bHoldToReload )
    {
        NumLoadedThisReload = 0;
    }
    ClientReload();
    Instigator.SetAnimAction(WeaponReloadAnim);
    if ( Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress && KFPlayerController(Instigator.Controller) != none &&
        Level.TimeSeconds - KFPlayerController(Instigator.Controller).LastReloadMessageTime > KFPlayerController(Instigator.Controller).ReloadMessageDelay )
    {
        KFPlayerController(Instigator.Controller).Speech('AUTO', 2, "");
        KFPlayerController(Instigator.Controller).LastReloadMessageTime = Level.TimeSeconds;
    }
}

simulated function ClientReload()
{
    local float ReloadMulti;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    if (MagAmmoRemaining <= 0)
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
    else if (MagAmmoRemaining >= 1)
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
}

function AddReloadedAmmo()
{
    local int a;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    if ( bShortReload )
        a++; // 1 bullet already bolted

    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    if ( PlayerController(Instigator.Controller) != none && KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements) != none )
    {
        KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements).OnWeaponReloaded();
    }
}

simulated function RenderOverlays( Canvas Canvas )
{
    if (HealAmmoCharge >= MaxAmmoCount) {
        if (!bWasFullyCharged) {
            bWasFullyCharged = true;
            MyHealth = 100;
            SetTextColor2(76,148,177);
            ++MyScriptedTexture.Revision;
        }
    }
    else {
        bWasFullyCharged = false;
        MyHealth = 100 * HealAmmoCharge / MaxAmmoCount;
        SetTextColor2(218,18,18);
        ++MyScriptedTexture.Revision;
    }

    if (AmmoAmount(0) <= 0) {
        if (OldValue != -5) {
            OldValue = -5;
            Skins[2] = ScopeRed;
            MyFont = SmallMyFont;
            SetTextColor(218,18,18);
            MyMessage = EmptyMessage;
            ++MyScriptedTexture.Revision;
        }
    }
    else if (bIsReloading) {
        if (OldValue != -4) {
            OldValue = -4;
            MyFont = SmallMyFont;
            SetTextColor(32,187,112);
            MyMessage = ReloadMessage;
            ++MyScriptedTexture.Revision;
        }
    }
    else if (OldValue != (MagAmmoRemaining+1)) {
        OldValue = MagAmmoRemaining + 1;
        Skins[2] = ScopeGreen;
        MyFont = Default.MyFont;

        if ((MagAmmoRemaining ) <= (MagCapacity/2))
            SetTextColor(32,187,112);
        if ((MagAmmoRemaining ) <= (MagCapacity/3))
        {
            SetTextColor(218,18,18);
            Skins[2] = ScopeRed;
        }
        if ((MagAmmoRemaining ) >= (MagCapacity/2))
            SetTextColor(76,148,177);
        MyMessage = String(MagAmmoRemaining);

        ++MyScriptedTexture.Revision;
    }

    MyScriptedTexture.Client = Self;
    Super(KFMedicGun).RenderOverlays(Canvas);
    MyScriptedTexture.Client = None;
}

defaultproperties
{
    ReloadShortAnim="Reload"
    ReloadShortRate=1.7
    ReloadAnim="Reload"
    ReloadRate=3.066
    MagCapacity=20

    ZoomedDisplayFOV=55 //fix for cool hud

    HealAmmoCharge=0
    FireModeClass(0)=class'ScrnM7A3MFire'
    FireModeClass(1)=class'ScrnM7A3MAltFire'
    bReduceMagAmmoOnSecondaryFire=False
    PickupClass=class'ScrnM7A3MPickup'
    ItemName="M7A3M Medic Gun SE"
}
