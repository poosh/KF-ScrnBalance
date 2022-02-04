class ToiletPaperExplode extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseCollision=True
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         UniformSize=True
         AutomaticInitialSpawning=False
         Acceleration=(X=20.000000,Y=-20.000000,Z=20.000000)
         DampingFactorRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
         ColorScale(0)=(Color=(R=200,G=200,B=200,A=255))
         ColorScale(1)=(RelativeTime=0.550000,Color=(R=200,G=200,B=200,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(A=255))
         FadeOutStartTime=1.040000
         FadeInEndTime=0.120000
         MaxParticles=15
         StartSizeRange=(X=(Min=2.000000,Max=5.000000),Y=(Min=2.000000,Max=5.000000),Z=(Min=2.000000,Max=5.000000))
         InitialParticlesPerSecond=5000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.MetalHitKF'
         LifetimeRange=(Min=2.000000,Max=2.000000)
         StartVelocityRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000),Z=(Min=-200.000000,Max=200.000000))
         VelocityLossRange=(X=(Min=0.100000,Max=0.100000),Y=(Min=0.100000,Max=0.100000),Z=(Min=0.100000,Max=0.100000))
     End Object
     Emitters(0)=SpriteEmitter0

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(R=200,G=200,B=200,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(R=200,G=200,B=200,A=255))
         FadeOutStartTime=0.020000
         MaxParticles=8
         StartSizeRange=(X=(Min=20.000000,Max=20.000000),Y=(Min=20.000000,Max=20.000000),Z=(Min=20.000000,Max=20.000000))
         InitialParticlesPerSecond=5000.000000
         Texture=Texture'KFX.MetalHitKF'
         LifetimeRange=(Min=0.250000,Max=0.250000)
     End Object
     Emitters(1)=SpriteEmitter1

     Begin Object Class=SpriteEmitter Name=SpriteEmitter2
         UseDirectionAs=PTDU_UpAndNormal
         UseCollision=True
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ScaleSizeXByVelocity=True
         AutomaticInitialSpawning=False
         DampingFactorRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
         ColorScale(0)=(Color=(R=200,G=200,B=200))
         ColorScale(1)=(RelativeTime=1.000000,Color=(R=255,G=255,B=255,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(R=255,G=255,B=255,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(R=100,G=100,B=100,A=255))
         ColorScale(4)=(RelativeTime=1.000000)
         ColorScale(5)=(RelativeTime=1.000000)
         ColorScale(6)=(RelativeTime=1.000000,Color=(R=200,G=200,B=200,A=255))
         FadeOutStartTime=0.336000
         FadeInEndTime=0.064000
         MaxParticles=20
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.250000)
         StartSizeRange=(X=(Min=15.000000,Max=15.000000),Y=(Min=5000.000000,Max=5000.000000),Z=(Min=5000.000000,Max=5000.000000))
         ScaleSizeByVelocityMultiplier=(X=0.010000,Y=0.010000)
         InitialParticlesPerSecond=5000.000000
         Texture=Texture'KFX.KFSparkHead'
         LifetimeRange=(Min=1.500000,Max=1.500000)
         StartVelocityRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000),Z=(Min=-200.000000,Max=200.000000))
     End Object
     Emitters(2)=SpriteEmitter2

     bNoDelete=False
     RemoteRole=ROLE_SimulatedProxy
     bNotOnDedServer=False
}
