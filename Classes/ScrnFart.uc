class ScrnFart extends Emitter;

var byte SizeScale;

replication
{
    reliable if ( Role == ROLE_Authority && bNetInitial )
        SizeScale;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    SetScale(SizeScale);
}

simulated function SetScale(byte Scale)
{
    //SizeScale = 1.0 + Scale * 0.4;
    SizeScale = Scale;
    Emitters[0].SizeScale[0].RelativeSize = 1.0 + 0.4*SizeScale;
    Emitters[0].SizeScale[1].RelativeSize = 3.0 + 1.2*SizeScale;
}


defaultproperties
{
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        UseColorScale=True
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        //BlendBetweenSubdivisions=True
        Name="SpriteEmitter0"
        Opacity=0.70000
        ColorScale(0)=(Color=(R=64,G=48,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(R=128,G=96,A=128))
        FadeOutFactor=(W=0.000000,X=0.000000,Y=0.000000,Z=0.000000)
        FadeOutStartTime=1.0
        SpinsPerSecondRange=(Y=(Min=0.050000,Max=0.100000),Z=(Min=0.050000,Max=0.100000))
        StartSpinRange=(X=(Min=-0.500000,Max=0.500000),Y=(Max=1.000000),Z=(Max=1.000000))
        SizeScale(0)=(RelativeSize=1.000000)
        SizeScale(1)=(RelativeTime=1.0,RelativeSize=3.000000)
        StartSizeRange=(X=(Min=20,Max=20),Y=(Min=20,Max=20),Z=(Min=20,Max=20))
        InitialParticlesPerSecond=5000.000000
        DrawStyle=PTDS_AlphaBlend
        Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
        TextureUSubdivisions=8
        TextureVSubdivisions=8
        LifetimeRange=(Min=4.0,Max=5.0)
        RespawnDeadParticles=False
        StartVelocityRange=(X=(Min=-750.000000,Max=750.000000),Y=(Min=-750.000000,Max=750.000000))
        VelocityLossRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
    End Object
    Emitters(0)=SpriteEmitter'ScrnBalanceSrv.ScrnFart.SpriteEmitter0'

    RemoteRole=ROLE_SimulatedProxy
    AutoDestroy=True
    bNoDelete=False
    bNetTemporary=True
    bDirectional=True
    LifeSpan=6
}
