class ScrnFlareCloud extends Emitter;

var float TTL;
var float FadeTime;
var transient vector OriginalSizeRange;


function PostBeginPlay()
{
    local vector Offset;

    OriginalSizeRange.X = Emitters[0].StartSizeRange.X.Max;
    OriginalSizeRange.Y = Emitters[0].StartSizeRange.Y.Max;
    OriginalSizeRange.Z = Emitters[0].StartSizeRange.Z.Max;

    SetBase(Owner);
    // randomize flare locations
    // Ideally would be to replicate the hit location, but it costly and sometimes buggy
    Offset.x = Owner.CollisionRadius * (frand() - 0.5);
    Offset.y = Owner.CollisionRadius * (frand() - 0.5);
    Offset.z = Owner.CollisionHeight * 0.5 * (frand() - 0.5);
    SetRelativeLocation(Offset);
    SetRelativeRotation(rot(0,0,0));


    SetTimer(TTL, false);
}

function PawnBaseDied()
{
    Kill();
}

function Timer()
{
    Kill();
}

function Tick(float dt)
{
    TTL -= dt;
    if ( TTL < FadeTime ) {
        Emitters[0].StartSizeRange.X.Max = OriginalSizeRange.X * TTL / FadeTime;
        Emitters[0].StartSizeRange.Y.Max = OriginalSizeRange.Y * TTL / FadeTime;
        Emitters[0].StartSizeRange.Z.Max = OriginalSizeRange.Z * TTL / FadeTime;
    }
}

function SetLifeSpan(float time)
{
    TTL = time;
    SetTimer(time, false);
}

function SetDamage(int Damage)
{
    local float ScaleFactor;

    ScaleFactor = lerp(Damage/200.0, 0.5, 2.0, true);
    Emitters[0].StartSizeRange.X.Max = default.Emitters[0].StartSizeRange.X.Max * ScaleFactor;
    Emitters[0].StartSizeRange.Y.Max = default.Emitters[0].StartSizeRange.Y.Max * ScaleFactor;
    OriginalSizeRange.X = Emitters[0].StartSizeRange.X.Max;
    OriginalSizeRange.Y = Emitters[0].StartSizeRange.Y.Max;
    OriginalSizeRange.Z = Emitters[0].StartSizeRange.Z.Max;
}


defaultproperties
{
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        UseColorScale=True
        FadeOut=True
        SpinParticles=True
        UseRegularSizeScale=False
        UniformSize=True
        BlendBetweenSubdivisions=True
        UseSubdivisionScale=True
        UseRandomSubdivision=True
        Acceleration=(Z=100.000000)
        ColorScale(0)=(Color=(R=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=50,G=75,R=255,A=255))
        ColorScale(2)=(RelativeTime=1.000000,Color=(B=113,G=113,R=255,A=255))
        ColorScaleRepeats=1.000000
        ColorMultiplierRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
        Opacity=0.700000
        FadeOutStartTime=1.060000
        CoordinateSystem=PTCS_Relative
        MaxParticles=50
        Name="SpriteEmitter0"
        StartLocationShape=PTLS_Sphere
        SphereRadiusRange=(Max=1.000000)
        SpinsPerSecondRange=(X=(Max=0.070000))
        StartSpinRange=(X=(Max=1.000000))
        SizeScale(0)=(RelativeSize=1.000000)
        StartSizeRange=(X=(Min=3.000000,Max=15.000000),Y=(Min=3.000000,Max=15.000000),Z=(Min=10.000000,Max=10.000000))
        ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
        ScaleSizeByVelocityMax=0.000000
        Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
        TextureUSubdivisions=8
        TextureVSubdivisions=8
        SubdivisionEnd=7
        SecondsBeforeInactive=30.000000
        LifetimeRange=(Min=0.700000,Max=1.200000)
        StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=1.000000,Max=100.000000))
        MaxAbsVelocity=(X=150.000000,Y=150.000000,Z=150.000000)
    End Object
    Emitters(0)=SpriteEmitter'ScrnBalanceSrv.ScrnFlareCloud.SpriteEmitter0'
    Begin Object Class=SpriteEmitter Name=SpriteEmitter2
        UseDirectionAs=PTDU_Up
        UseCollision=True
        UseColorScale=True
        FadeOut=True
        FadeIn=True
        UseRegularSizeScale=False
        UniformSize=True
        ScaleSizeYByVelocity=True
        BlendBetweenSubdivisions=True
        UseRandomSubdivision=True
        Acceleration=(Z=-500.000000)
        ColorScale(0)=(Color=(R=255))
        ColorScale(1)=(RelativeTime=0.200000,Color=(B=50,G=100,R=242))
        ColorScale(2)=(RelativeTime=0.400000,Color=(B=50,G=100,R=255))
        ColorScale(3)=(RelativeTime=1.000000,Color=(B=100,G=100,R=255))
        FadeOutStartTime=0.208000
        FadeInEndTime=0.100000
        MaxParticles=7
        SizeScale(2)=(RelativeTime=0.070000,RelativeSize=1.000000)
        SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
        StartSizeRange=(X=(Min=3.000000,Max=3.000000),Y=(Min=3.000000,Max=3.000000),Z=(Min=3.000000,Max=3.000000))
        ScaleSizeByVelocityMultiplier=(Y=0.005000)
        InitialParticlesPerSecond=500.000000
        Texture=Texture'KFX.KFSparkHead'
        TextureUSubdivisions=1
        TextureVSubdivisions=2
        LifetimeRange=(Min=0.300000,Max=0.700000)
        StartVelocityRange=(X=(Min=-300.000000,Max=300.000000),Y=(Min=-300.000000,Max=300.000000),Z=(Max=500.000000))
    End Object
    Emitters(1)=SpriteEmitter'SpriteEmitter2'
     AutoDestroy=True
     AutoReset=True
     bNoDelete=False
     Physics=PHYS_Trailer
     bHardAttach = True

     TTL=8.0
     FadeTime=5.0
}
