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
         ColorScale(0)=(Color=(R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=174,G=174,R=255,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=113,G=113,R=255,A=255))
         ColorScaleRepeats=1.000000
         ColorMultiplierRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
         FadeOutStartTime=0.500000
         CoordinateSystem=PTCS_Relative
         MaxParticles=50
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=1.000000)
         SpinsPerSecondRange=(X=(Max=0.070000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=1.000000)
         StartSizeRange=(X=(Min=20.000000,Max=50.000000),Y=(Min=20.000000,Max=50.000000),Z=(Max=50.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=0.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
         TextureUSubdivisions=8
         TextureVSubdivisions=8
         SubdivisionEnd=7
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=2.000000)
         StartVelocityRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=1.000000,Max=1.000000),Z=(Min=20.000000,Max=100.000000))
         MaxAbsVelocity=(X=100.000000,Y=100.000000,Z=100.000000)
     End Object
     Emitters(0)=SpriteEmitter'ScrnBalanceSrv.ScrnFlareCloud.SpriteEmitter0'

     AutoDestroy=True
     AutoReset=True
     bNoDelete=False
     Physics=PHYS_Trailer
     bHardAttach = True

     TTL=8.0
     FadeTime=5.0
}
