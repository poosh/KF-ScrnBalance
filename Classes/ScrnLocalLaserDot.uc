class ScrnLocalLaserDot extends DynamicProjector;

#exec OBJ LOAD FILE=ScrnTex.utx

struct SLaser {
    var Color LaserColor;
    var Material DotTexture, Skin3rd;
};
var const array<SLaser> Lasers;

var private byte LaserType;

var()       float                       ProjectorPullback;      // Amount to pull back the laser dot projector from the hit location


simulated function color GetLaserColor()
{
    return Lasers[LaserType].LaserColor;
}


static function Color GetLaserColorStatic(byte LaserType)
{
    if ( LaserType >= default.Lasers.Length )
        LaserType = 0;

    return default.Lasers[LaserType].LaserColor;
}

simulated function byte GetLaserType()
{
    return LaserType;
}

simulated function SetLaserType(byte value)
{
    if ( value >= Lasers.length )
        value = 0;

    LaserType = value;
    ProjTexture = Lasers[LaserType].DotTexture;
    bHidden = LaserType == 0 || ProjTexture == none;
}



defaultproperties
{
    Lasers(0)=(LaserColor=(R=0,G=0,B=0,A=1));
    Lasers(1)=(LaserColor=(R=255,G=0,B=0,A=255),DotTexture=Texture'ScrnTex.Laser.Laser_Dot_Red',Skin3rd=Texture'ScrnTex.Laser.Laser_Red')
    Lasers(2)=(LaserColor=(R=0,G=255,B=0,A=255),DotTexture=Texture'ScrnTex.Laser.Laser_Dot_Green',Skin3rd=Texture'ScrnTex.Laser.Laser_Green')
    Lasers(3)=(LaserColor=(R=0,G=150,B=255,A=255),DotTexture=Texture'ScrnTex.Laser.Laser_Dot_Blue',Skin3rd=Texture'ScrnTex.Laser.Laser_Blue')
    Lasers(4)=(LaserColor=(R=255,G=150,B=0,A=255),DotTexture=Texture'ScrnTex.Laser.Laser_Dot_Orange',Skin3rd=Texture'ScrnTex.Laser.Laser_Orange')

    MaterialBlendingOp=PB_Add
    FrameBufferBlendingOp=PB_Add
    ProjTexture=none
    ProjectorPullback=1.0
    FOV=5
    MaxTraceDistance=100
    bClipBSP=True
    bProjectOnUnlit=True
    bGradient=True
    bProjectOnAlpha=True
    bProjectOnParallelBSP=True
    bNoProjectOnOwner=True
    DrawType=DT_None
    bLightChanged=True
    bHidden=True
    RemoteRole=ROLE_None
    bSkipActorPropertyReplication=True
    DrawScale=0.250000
    LifeSpan=100000000
}
