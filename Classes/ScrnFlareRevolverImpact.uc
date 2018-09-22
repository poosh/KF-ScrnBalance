// Impact effect for flare pistol
class ScrnFlareRevolverImpact extends FlameImpact;

simulated function PostBeginPlay()
{
    Super.Postbeginplay();
    DoLight();
}
simulated function DoLight()
{
    if ( !Level.bDropDetail && (Instigator != None)
        && ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
        bDynamicLight = true;
        SetTimer(0.1, true);
    }
    else Timer();
}

simulated function Timer()
{
    LightRadius = LightRadius*0.8;
    LightBrightness = LightBrightness*0.8;
    if (LightRadius < 2)
    {
        bDynamicLight = false;
        SetTimer(0, false); //disable timer
    }
}


defaultproperties
{
    //red smoke
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        Disabled=True
        UseColorScale=True
        RespawnDeadParticles=False
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        Acceleration=(Z=15.000000)
        ColorScale(0)=(Color=(R=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=64,G=64,R=64))
        Opacity=0.35
        MaxParticles=6
        Name="SpriteEmitter0"
        StartLocationShape=PTLS_Sphere
        SphereRadiusRange=(Min=20.000000,Max=20.000000)
        MeshScaleRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
        SpinsPerSecondRange=(X=(Max=0.100000))
        StartSpinRange=(X=(Max=1.000000))
        SizeScale(0)=(RelativeSize=0.700000)
        SizeScale(1)=(RelativeTime=1.000000,RelativeSize=5.000000)
        StartSizeRange=(X=(Min=10.000000,Max=20.000000),Y=(Min=20.000000,Max=20.000000),Z=(Min=20.000000,Max=20.000000))
        InitialParticlesPerSecond=32.000000
        DrawStyle=PTDS_Brighten
        Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
        TextureUSubdivisions=8
        TextureVSubdivisions=8
        SecondsBeforeInactive=0.000000
        LifetimeRange=(Min=1.000000,Max=1.000000)
        StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=25.000000,Max=50.000000))
    End Object
    Emitters(0)=SpriteEmitter'SpriteEmitter0'
    //white smoke
    Begin Object Class=SpriteEmitter Name=SpriteEmitter1
        Disabled=True
        UseColorScale=True
        RespawnDeadParticles=False
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        Acceleration=(Z=150.000000)
        ColorScale(0)=(Color=(R=255,A=128))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=64,G=64,R=64))
        Opacity=0.35
        MaxParticles=6
        Name="SpriteEmitter1"
        StartLocationShape=PTLS_Sphere
        SphereRadiusRange=(Min=10.000000,Max=10.000000)
        SpinsPerSecondRange=(X=(Max=0.100000))
        StartSpinRange=(X=(Max=1.000000))
        SizeScale(0)=(RelativeSize=0.700000)
        SizeScale(1)=(RelativeTime=1.000000,RelativeSize=5.000000)
        StartSizeRange=(X=(Min=10.000000,Max=20.000000),Y=(Min=10.000000,Max=20.000000),Z=(Min=50.000000,Max=50.000000))
        InitialParticlesPerSecond=32.000000
        DrawStyle=PTDS_Brighten
        Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
        TextureUSubdivisions=8
        TextureVSubdivisions=8
        LifetimeRange=(Min=1.000000,Max=1.000000)
        StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000))
    End Object
    Emitters(1)=SpriteEmitter'SpriteEmitter1'

    //annoying red flash
    Begin Object Class=SpriteEmitter Name=SpriteEmitter2
        UseColorScale=True
        FadeOut=True
        FadeIn=True
        RespawnDeadParticles=False
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        BlendBetweenSubdivisions=True
        UseSubdivisionScale=True
        Opacity=0.70
        Acceleration=(Z=50.000000)
        ColorScale(0)=(Color=(R=255,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=100,G=150,R=255,A=255))
        FadeOutStartTime=0.102500
        FadeInEndTime=0.050000
        MaxParticles=2
        Name="SpriteEmitter2"
        SizeScale(1)=(RelativeTime=0.140000,RelativeSize=1.000000)
        SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.000000)
        StartSizeRange=(X=(Min=10.000000,Max=15.000000),Y=(Min=10.000000,Max=15.000000),Z=(Min=10.000000,Max=15.000000))
        InitialParticlesPerSecond=30.000000
        DrawStyle=PTDS_Brighten
        Texture=Texture'Effects_Tex.explosions.impact_2frame'
        TextureUSubdivisions=2
        TextureVSubdivisions=1
        LifetimeRange=(Min=0.200000,Max=0.200000)
        StartVelocityRange=(Z=(Min=10.000000,Max=10.000000))
    End Object
    Emitters(2)=SpriteEmitter'SpriteEmitter2'

    //ton of sparks
    Begin Object Class=SpriteEmitter Name=SpriteEmitter3
        UseDirectionAs=PTDU_Up
        UseCollision=True
        UseColorScale=True
        FadeOut=True
        RespawnDeadParticles=False
        UniformSize=True
        AutomaticInitialSpawning=False
        Acceleration=(Z=-500.000000)
        ColorScale(0)=(Color=(R=255,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=155,G=155,R=255,A=255))
        FadeOutStartTime=0.800000
        MaxParticles=10 //20
        Name="SpriteEmitter3"
        StartSizeRange=(X=(Min=5.000000,Max=5.000000),Y=(Min=0.100000,Max=0.100000),Z=(Min=5.000000,Max=5.000000))
        InitialParticlesPerSecond=5000.000000
        DrawStyle=PTDS_Brighten
        Texture=Texture'KFX.KFSparkHead'
        LifetimeRange=(Min=0.700000,Max=1.000000)
        StartVelocityRange=(X=(Min=-500.000000,Max=500.000000),Y=(Min=-500.000000,Max=500.000000),Z=(Max=500.000000))
    End Object
    Emitters(3)=SpriteEmitter'SpriteEmitter3'

    //a fire, but its disabled
    Begin Object Class=SpriteEmitter Name=SpriteEmitter4
        FadeOut=True
        FadeIn=True
        RespawnDeadParticles=False
        Disabled=True
        Backup_Disabled=True
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        UseRandomSubdivision=True
        Acceleration=(Z=125.000000)
        ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
        ColorScale(2)=(RelativeTime=0.667857,Color=(B=172,G=172,R=255,A=255))
        ColorScale(3)=(RelativeTime=1.000000,Color=(B=128,G=128,R=128,A=255))
        ColorScale(4)=(RelativeTime=1.000000)
        ColorScale(5)=(RelativeTime=1.000000)
        FadeOutStartTime=0.200000
        FadeInEndTime=0.140000
        MaxParticles=2
        Name="SpriteEmitter4"
        StartLocationRange=(Z=(Min=25.000000,Max=25.000000))
        SpinsPerSecondRange=(X=(Max=0.100000))
        StartSpinRange=(X=(Min=-0.500000,Max=0.500000))
        SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.500000)
        StartSizeRange=(X=(Min=35.000000,Max=50.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
        ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
        ScaleSizeByVelocityMax=0.000000
        InitialParticlesPerSecond=5000.000000
        Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
        TextureUSubdivisions=4
        TextureVSubdivisions=4
        SecondsBeforeInactive=30.000000
        LifetimeRange=(Min=0.500000,Max=0.500000)
        StartVelocityRange=(Z=(Min=75.000000,Max=75.000000))
    End Object
    Emitters(4)=SpriteEmitter'SpriteEmitter4'

    
    Begin Object Class=SpriteEmitter Name=SpriteEmitter5
        UseColorScale=True
        FadeOut=True
        FadeIn=True
        RespawnDeadParticles=False
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        Opacity=0.7
        ColorScale(0)=(Color=(R=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=150,G=150,R=255,A=255))
        FadeOutStartTime=0.200000
        FadeInEndTime=0.140000
        MaxParticles=1
        Name="SpriteEmitter5"
        SpinsPerSecondRange=(X=(Max=0.100000))
        StartSpinRange=(X=(Min=-0.500000,Max=0.500000))
        SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.500000)
        StartSizeRange=(X=(Min=70.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
        ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
        ScaleSizeByVelocityMax=0.000000
        InitialParticlesPerSecond=5000.000000
        Texture=Texture'Icebreaker_T.Coronas.SoftFlare'
        TextureUSubdivisions=1
        TextureVSubdivisions=1
        SecondsBeforeInactive=30.000000
        LifetimeRange=(Min=0.500000,Max=0.500000)
    End Object
    Emitters(5)=SpriteEmitter'SpriteEmitter5'

    bNoDelete = false
    AutoDestroy = true

    SoundVolume = 255
    SoundRadius = 100
    bFullVolume = false
    AmbientSound = Sound'Amb_Destruction.Kessel_Fire_Small_Vehicle'//Sound'GeneralAmbience.firefx12' KFTODO: Replace this
/*
    LightRadius = 3
    LightType = LT_Steady //LT_Pulse

    LightBrightness = 170 //255
    LightHue = 255
    LightSaturation = 64 //64
    bDynamicLight = false //true
*/

    LightType=LT_Steady
    LightBrightness=255
    LightRadius=16.000000
    LightHue=255
    LightSaturation=64
    LightCone=16
    bDynamicLight=false //true

    FlameDamage = 10
    BurnInterval = 1

    LifeSpan=6
    
    
}
