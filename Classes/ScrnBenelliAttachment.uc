class ScrnBenelliAttachment extends ScrnLaserWeaponAttachment;

var Actor TacShine;
var  Effects TacShineCorona;
var bool bBeamEnabled;

replication
{
    reliable if ( Role==ROLE_Authority )
        bBeamEnabled;
}

// Prevents tracers from spawning if player is using the flashlight function of the 9mm
simulated event ThirdPersonEffects()
{
    if( FiringMode==1 )
        return;
    Super.ThirdPersonEffects();
}

simulated function Destroyed()
{
    if ( TacShineCorona != None )
        TacShineCorona.Destroy();
    if ( TacShine != None )
        TacShine.Destroy();
    Super.Destroyed();
}

simulated function UpdateTacBeam( float Dist )
{
    local vector Sc;

    if( !bBeamEnabled )
    {
        if (TacShine == none )
        {
            TacShine = Spawn(Class'Single'.Default.TacShineClass,Owner,,,);
            AttachToBone(TacShine, LaserAttachmentBone);
            TacShine.RemoteRole = ROLE_None;
        }
        else TacShine.bHidden = False;
        if (TacShineCorona == none )
        {
            TacShineCorona = Spawn(class 'KFTacLightCorona',Owner,,,);
            AttachToBone(TacShineCorona,LaserAttachmentBone);
            TacShineCorona.RemoteRole = ROLE_None;
        }
        TacShineCorona.bHidden = False;
        bBeamEnabled = True;
    }
    Sc = TacShine.DrawScale3D;
    Sc.Y = FClamp(Dist/90.f,0.02,1.f);
    if( TacShine.DrawScale3D!=Sc )
        TacShine.SetDrawScale3D(Sc);
}

simulated function TacBeamGone()
{
    if( bBeamEnabled )
    {
        if (TacShine!=none )
            TacShine.bHidden = True;
        if (TacShineCorona!=none )
            TacShineCorona.bHidden = True;
        bBeamEnabled = False;
    }
}

defaultproperties
{
    LaserAttachmentBone="FlashLight"
    mMuzFlashClass=Class'ROEffects.MuzzleFlash3rdKar'
    mShellCaseEmitterClass=Class'KFMod.KFShotgunShellSpewer'
    MeshRef="KF_Weapons3rd3_Trip.Benelli_3rd"

    MovementAnims(0)=JogF_Shotgun
    MovementAnims(1)=JogB_Shotgun
    MovementAnims(2)=JogL_Shotgun
    MovementAnims(3)=JogR_Shotgun
    CrouchAnims(0)=CHwalkF_Shotgun
    CrouchAnims(1)=CHwalkB_Shotgun
    CrouchAnims(2)=CHwalkL_Shotgun
    CrouchAnims(3)=CHwalkR_Shotgun
    WalkAnims(0)=WalkF_Shotgun
    WalkAnims(1)=WalkB_Shotgun
    WalkAnims(2)=WalkL_Shotgun
    WalkAnims(3)=WalkR_Shotgun
    AirStillAnim=JumpF_Mid
    AirAnims(0)=JumpF_Mid
    AirAnims(1)=JumpF_Mid
    AirAnims(2)=JumpL_Mid
    AirAnims(3)=JumpR_Mid
    TakeoffStillAnim=JumpF_Takeoff
    TakeoffAnims(0)=JumpF_Takeoff
    TakeoffAnims(1)=JumpF_Takeoff
    TakeoffAnims(2)=JumpL_Takeoff
    TakeoffAnims(3)=JumpR_Takeoff
    LandAnims(0)=JumpF_Land
    LandAnims(1)=JumpF_Land
    LandAnims(2)=JumpL_Land
    LandAnims(3)=JumpR_Land

    TurnRightAnim=TurnR_Shotgun
    TurnLeftAnim=TurnL_Shotgun
    CrouchTurnRightAnim=CH_TurnR_Shotgun
    CrouchTurnLeftAnim=CH_TurnL_Shotgun
    IdleRestAnim=Idle_Shotgun//Idle_Rest
    IdleCrouchAnim=CHIdle_Shotgun
    IdleSwimAnim=Swim_Tread
    IdleWeaponAnim=Idle_Shotgun//Idle_Rifle
    IdleHeavyAnim=Idle_Shotgun//Idle_Biggun
    IdleRifleAnim=Idle_Shotgun//Idle_Rifle
    IdleChatAnim=Idle_Shotgun
    FireAnims(0)=Fire_Benelli
    FireAnims(1)=Fire_Benelli
    FireAnims(2)=Fire_Benelli
    FireAnims(3)=Fire_Benelli
    FireAltAnims(0)=Fire_Benelli
    FireAltAnims(1)=Fire_Benelli
    FireAltAnims(2)=Fire_Benelli
    FireAltAnims(3)=Fire_Benelli
    FireCrouchAnims(0)=CHFire_Benelli
    FireCrouchAnims(1)=CHFire_Benelli
    FireCrouchAnims(2)=CHFire_Benelli
    FireCrouchAnims(3)=CHFire_Benelli
    FireCrouchAltAnims(0)=CHFire_Benelli
    FireCrouchAltAnims(1)=CHFire_Benelli
    FireCrouchAltAnims(2)=CHFire_Benelli
    FireCrouchAltAnims(3)=CHFire_Benelli
    HitAnims(0)=HitF_Shotgun
    HitAnims(1)=HitB_Shotgun
    HitAnims(2)=HitL_Shotgun
    HitAnims(3)=HitR_Shotgun
    PostFireBlendStandAnim=Blend_Shotgun
    PostFireBlendCrouchAnim=CHBlend_Shotgun
}
