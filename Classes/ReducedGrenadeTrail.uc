class ReducedGrenadeTrail extends PanzerfaustTrail;

simulated function HandleOwnerDestroyed()
{
    Emitters[0].ParticlesPerSecond = 0;
    Emitters[0].InitialParticlesPerSecond = 0;
    Emitters[0].RespawnDeadParticles=false;

    Emitters[1].ParticlesPerSecond = 0;
    Emitters[1].InitialParticlesPerSecond = 0;
    Emitters[1].RespawnDeadParticles=false;

    AutoDestroy=true;
}

defaultproperties
{
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        FadeOut=True
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        UseVelocityScale=True
        Acceleration=(X=35.000000,Z=10.000000) //70, 20
        ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
        FadeOutStartTime=0.350000 //old fade 0.95
        MaxParticles=200 //200
        Opacity=1.00 //added this
        Name="SpriteEmitter2"
        UseRotationFrom=PTRS_Actor
        SpinsPerSecondRange=(X=(Min=-0.075000,Max=0.075000))
        SizeScale(0)=(RelativeSize=1.000000)
        SizeScale(1)=(RelativeTime=0.070000,RelativeSize=1.000000)
        SizeScale(2)=(RelativeTime=0.370000,RelativeSize=1.3500000) //2.2
        SizeScale(3)=(RelativeTime=1.000000,RelativeSize=2.000000) //4.0
        StartSizeRange=(X=(Min=6.000000,Max=14.000000)) //min 15 max 30
        ParticlesPerSecond=50.000000 //25
        InitialParticlesPerSecond=50.000000 //25
        DrawStyle=PTDS_AlphaBlend
        Texture=Texture'Effects_Tex.explosions.DSmoke_2'
        LifetimeRange=(Max=2.000000) //5.0
        StartVelocityRange=(X=(Min=15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-15.000000,Max=15.000000)) //45 on all
        VelocityLossRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=1.000000,Max=1.000000),Z=(Min=1.000000,Max=1.000000))
        VelocityScale(0)=(RelativeVelocity=(X=1.000000,Y=1.000000,Z=1.000000))
        VelocityScale(1)=(RelativeTime=0.300000,RelativeVelocity=(X=0.200000,Y=1.000000,Z=1.000000)) //0.2, 1.0, 1.0
        VelocityScale(2)=(RelativeTime=1.000000,RelativeVelocity=(Y=0.400000,Z=0.400000)) //0.4, 0.4
    End Object
    Emitters(0)=SpriteEmitter'SpriteEmitter0'

    Begin Object Class=SpriteEmitter Name=SpriteEmitter1
        UseColorScale=True
        FadeOut=True
        AutoReset=True
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        UseVelocityScale=True
        Acceleration=(X=35.000000,Z=10.000000) //70, 20
        ColorScale(0)=(Color=(B=60,G=60,R=60,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=117,G=117,R=117,A=255))
        FadeOutStartTime=0.500000 //1.2
        MaxParticles=200 //200
        Opacity=1.00 //added this
        AutoResetTimeRange=(Min=5.000000,Max=10.000000)
        Name="SpriteEmitter4"
        UseRotationFrom=PTRS_Actor
        SpinsPerSecondRange=(X=(Min=-0.075000,Max=0.075000))
        SizeScale(0)=(RelativeSize=1.000000)
        SizeScale(1)=(RelativeTime=0.070000,RelativeSize=1.000000)
        SizeScale(2)=(RelativeTime=0.370000,RelativeSize=1.700000) //2.2
        SizeScale(3)=(RelativeTime=1.000000,RelativeSize=2.000000) //3.0
        StartSizeRange=(X=(Min=5.000000,Max=10.000000)) //11, 21
        ParticlesPerSecond=50.000000 //25
        InitialParticlesPerSecond=50.000000 //25
        DrawStyle=PTDS_AlphaBlend
        Texture=Texture'Effects_Tex.explosions.DSmoke_2'
        LifetimeRange=(Max=1.700000) //4.0
        StartVelocityRange=(X=(Min=10.000000,Max=20.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-15.000000,Max=15.000000)) //a mess of numbers
        VelocityLossRange=(X=(Min=2.000000,Max=2.000000),Y=(Min=2.000000,Max=2.000000),Z=(Min=2.000000,Max=2.000000))
        VelocityScale(0)=(RelativeVelocity=(X=1.000000,Y=1.000000,Z=1.000000))
        VelocityScale(1)=(RelativeTime=0.400000,RelativeVelocity=(X=0.150000,Y=1.000000,Z=1.000000))
        VelocityScale(2)=(RelativeTime=1.000000,RelativeVelocity=(Y=0.400000,Z=0.400000))
    End Object
    Emitters(1)=SpriteEmitter'SpriteEmitter1'

    bNoDelete=false
    AutoDestroy=False
}
