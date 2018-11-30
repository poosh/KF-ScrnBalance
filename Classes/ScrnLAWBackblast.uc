class ScrnLAWBackblast extends Emitter;

simulated function Trigger(Actor Other, Pawn EventInstigator)
{
	Emitters[0].SpawnParticle(30);
	//Emitters[1].SpawnParticle(1);
}

defaultproperties
{   
    Begin Object Class=SpriteEmitter Name=ScrnLAWBackblastEmitter
        UseColorScale=True
        RespawnDeadParticles=False
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        Acceleration=(Y=-150.000000)
        ColorScale(0)=(Color=(B=160,G=160,R=160,A=255))
        ColorScale(1)=(RelativeTime=0.250000,Color=(B=180,G=180,R=180,A=200))
        ColorScale(2)=(RelativeTime=1.000000,Color=(B=200,G=200,R=200))
        MaxParticles=50
        Name="ScrnLAWBackblastEmitter"
        StartLocationShape=PTLS_Sphere
        MeshScaleRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
        SpinsPerSecondRange=(X=(Max=1.000000))
        StartSpinRange=(X=(Min=-0.500000,Max=0.500000))
        SizeScale(0)=(RelativeSize=0.700000)
        SizeScale(1)=(RelativeTime=1.000000,RelativeSize=5.000000)
        StartSizeRange=(X=(Min=10.000000,Max=20.000000),Y=(Min=10.000000,Max=20.000000),Z=(Min=10.000000,Max=20.000000))
        InitialParticlesPerSecond=1000.000000
        DrawStyle=PTDS_AlphaBlend
        Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
        TextureUSubdivisions=8
        TextureVSubdivisions=8
        SecondsBeforeInactive=0.000000
        LifetimeRange=(Min=0.500000,Max=1.500000)
        StartVelocityRange=(X=(Max=25.000000),Y=(Min=200.000000,Max=350.000000),Z=(Max=25.000000)) //(X=(Min=200.000000,Max=350.000000),Y=(Max=25.000000),Z=(Max=25.000000))
    End Object
    Emitters(0)=SpriteEmitter'ScrnLAWBackblastEmitter'

	AutoDestroy=True
    bUnlit=false
    bDirectional=True
    bNoDelete=false
    RemoteRole=ROLE_None
    bNetTemporary=true
    LifeSpan = 4
}
