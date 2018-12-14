// actors of this class are not replicated and should be spawned directly on client side
class ScrnLaserBeam3rd extends xEmitter
    dependson(ScrnLocalLaserDot);

#exec OBJ LOAD FILE=ScrnTex.utx

var class<ScrnLocalLaserDot>        LaserDotClass;
var protected ScrnLocalLaserDot     LaserDot;
var private byte                    LaserType;

var KFWeaponAttachment MyWeaponAttachment;
var name MyAttachmentBone;

var() float DotProjectorPullback;

simulated function PostBeginPlay()
{
    LaserDot = spawn(LaserDotClass, self);
}

simulated function Destroyed()
{
    LaserDot.Destroy();
    super.Destroyed();
}

simulated function byte GetLaserType()
{
    return LaserType;
}

simulated function ForceLaserType(out byte value)
{
    local ScrnPlayerController PC;

    PC = ScrnPlayerController(Level.GetLocalPlayerController());
    if( PC != none && PC.bOtherPlayerLasersBlue
            && (Owner == none || Owner.Instigator == none || Owner.Instigator.Controller != PC) )
    {
        value = 3; // force blue laser color
    }
}

simulated function SetLaserType(byte value)
{
    ForceLaserType(value);

    LaserDot.SetLaserType(value);
    LaserType = LaserDot.GetLaserType();
    Skins[0] = LaserDot.Lasers[LaserType].Skin3rd;
    bHidden = LaserType == 0 || Skins[0] == none;
}

simulated function AdjustDotPosition()
{
    local Coords C;
    local Vector StartTrace, EndTrace, X;
    //local Vector Y,Z;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    // local Rotator R;

    if ( LaserType == 0 || MyWeaponAttachment == none || Instigator == none || Instigator.IsFirstPerson() ) {
        // not replicated yet?
        bHidden = true;
        LaserDot.bHidden = true;
        LaserDot.ProjTexture = none;
        return;
    }

    // if ( Level.TimeSeconds - MyWeaponAttachment.LastRenderTime < 1 ) {
        // weapon attachment replicated and updated
        bHidden = false;
        C = MyWeaponAttachment.GetBoneCoords(MyAttachmentBone);
        mSpawnVecA = C.Origin;
        SetRotation(Rotator(-C.XAxis));
        SetLocation( mSpawnVecA + C.XAxis * 50 );

        X = C.XAxis;
        StartTrace = Location;
    // }
    // else  {
        // bHidden = true;
        // R = Instigator.GetViewRotation();
        // if ( Instigator.Controller == none ) // client, not owner
            // R.Pitch = Instigator.ViewPitch;
        // GetAxes(R, X, Y, Z);
        // StartTrace = Instigator.Location + X*Instigator.CollisionRadius;
    // }

    EndTrace = StartTrace + 5000*X;
    Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
    if (Other != None && Other != Instigator && Other.Base != Instigator ) {
        LaserDot.bHidden = false;
        LaserDot.SetLocation(HitLocation - X*LaserDot.ProjectorPullback);
        if( HitNormal == vect(0,0,0) )
            LaserDot.SetRotation(Rotator(X));
        else
            LaserDot.SetRotation(Rotator(-HitNormal));
    }
    else
        LaserDot.bHidden = true;

    if ( !LaserDot.bHidden && LaserDot.ProjTexture == none )
        LaserDot.SetLaserType(LaserType); // update proj texture
}

simulated function Tick(float dt)
{
    if (  LaserType > 0 )
        AdjustDotPosition();
}


defaultproperties
{
    LaserDotClass=class'ScrnLocalLaserDot'
    MyAttachmentBone="Tip"
    bHardAttach=False

     //SpotProjectorPullback=1.000000
     mParticleType=PT_Beam
     mMaxParticles=3
     mRegenDist=100.000000
     mSizeRange(0)=4.000000
     mSizeRange(1)=5.000000
     mColorRange(0)=(B=100,G=100,R=100)
     mColorRange(1)=(B=100,G=100,R=100)
     mAttenuate=False
     mAttenKa=1.000000
     bHidden=True
     RemoteRole=ROLE_None
     bSkipActorPropertyReplication=True
     LifeSpan=100000000
     Skins(0)=none
     Style=STY_Additive
     SoundVolume=45
     SoundRadius=120.000000
     DotProjectorPullback=1.0
}
