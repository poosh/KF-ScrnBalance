class ScrnFlareRevolverTrail extends Emitter;

defaultproperties
{
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        UniformSize=True
        ColorScale(0)=(Color=(R=255,A=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
        ColorMultiplierRange=(Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
        Opacity=0.330000
        FadeOutStartTime=10.000000
        CoordinateSystem=PTCS_Relative
        MaxParticles=1
        Name="SpriteEmitter0"
        StartSizeRange=(X=(Min=40.000000,Max=40.000000),Y=(Min=40.000000,Max=40.000000),Z=(Min=40.000000,Max=40.000000))
        InitialParticlesPerSecond=1.000000
        Texture=Texture'Waterworks_T.General.glow_dam01'
        LifetimeRange=(Min=0.100000,Max=0.100000)
        WarmupTicksPerSecond=1.000000
        RelativeWarmupTime=30.000000
    End Object
    Emitters(0)=SpriteEmitter'SpriteEmitter0'

    Begin Object Class=SpriteEmitter Name=SpriteEmitter1
        UseColorScale=True
        FadeOut=True
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        BlendBetweenSubdivisions=True
        UseSubdivisionScale=True
        UseRandomSubdivision=True
        ColorScale(0)=(Color=(R=255))
        ColorScale(1)=(RelativeTime=0.303571,Color=(B=128,G=128,R=128,A=255))
        ColorScale(2)=(RelativeTime=1.000000,Color=(B=128,G=128,R=128,A=255))
        ColorScale(3)=(RelativeTime=1.000000,Color=(B=128,G=128,R=128))
        ColorMultiplierRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
        FadeOutStartTime=0.501500
        Opacity=0.5
        MaxParticles=50
        Name="SpriteEmitter1"
        StartLocationShape=PTLS_Sphere
        SphereRadiusRange=(Max=1.000000)
        SpinsPerSecondRange=(X=(Max=0.070000))
        StartSpinRange=(X=(Max=1.000000))
        SizeScale(0)=(RelativeTime=1.000000,RelativeSize=2.000000)
        StartSizeRange=(X=(Min=1.000000,Max=7.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
        ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
        ScaleSizeByVelocityMax=0.000000
        DrawStyle=PTDS_Brighten
        Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
        TextureUSubdivisions=8
        TextureVSubdivisions=8
        SubdivisionEnd=7
        SecondsBeforeInactive=30.000000
        LifetimeRange=(Min=0.450000,Max=0.850000)
        StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=2.000000,Max=25.000000))
        MaxAbsVelocity=(X=100.000000,Y=100.000000,Z=100.000000)
    End Object
    Emitters(1)=SpriteEmitter'SpriteEmitter1'

    Begin Object Class=SpriteEmitter Name=SpriteEmitter2
        UseDirectionAs=PTDU_Up
        UseColorScale=True
        FadeOut=True
        UseRegularSizeScale=False
        ScaleSizeYByVelocity=True
        Acceleration=(Z=-250.000000)
        DampingFactorRange=(X=(Min=0.200000),Y=(Min=0.200000),Z=(Min=0.200000,Max=0.500000))
        ColorScale(0)=(Color=(R=255))
        ColorScale(1)=(RelativeTime=1.000000,Color=(B=155,G=155,R=255,A=0))
        FadeOutStartTime=0.500000
        MaxParticles=75
        Name="SpriteEmitter2"
        DetailMode=DM_High
        UseRotationFrom=PTRS_Actor
        SizeScale(2)=(RelativeTime=0.070000,RelativeSize=1.000000)
        SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
        StartSizeRange=(X=(Min=0.500000,Max=1.500000),Y=(Min=0.500000,Max=1.500000),Z=(Min=0.500000,Max=1.500000))
        ScaleSizeByVelocityMultiplier=(Y=0.020000)
        DrawStyle=PTDS_Brighten
        Texture=Texture'KFX.KFSparkHead'
        TextureUSubdivisions=1
        TextureVSubdivisions=1
        LifetimeRange=(Min=0.700000,Max=1.000000)
        StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=-50.000000,Max=75.000000))
    End Object
    Emitters(2)=SpriteEmitter'SpriteEmitter2'



    bNetTemporary=True
    RemoteRole=ROLE_None

    bNoDelete=false
    Physics=PHYS_Trailer

    DrawScale = 1.0
}


