class ScrnNadeHealing extends Emitter;

var bool bFlashed;

simulated function PostBeginPlay()
{
    Super.Postbeginplay();
    NadeLight();
}

simulated function NadeLight()
{
    if ( !Level.bDropDetail && (Instigator != None)
        && ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
        bDynamicLight = true;
        SetTimer(0.25, false);
    }
    else Timer();
}

simulated function Timer()
{
    bDynamicLight = false;
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
         ColorScale(0)=(Color=(G=255,R=128,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=61,G=105,R=61,A=255))
         FadeOutFactor=(W=0.000000,X=0.000000,Y=0.000000,Z=0.000000)
         FadeOutStartTime=9.000000
         SpinsPerSecondRange=(Y=(Min=0.050000,Max=0.100000),Z=(Min=0.050000,Max=0.100000))
         StartSpinRange=(X=(Min=-0.500000,Max=0.500000),Y=(Max=1.000000),Z=(Max=1.000000))
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.0,RelativeSize=5.000000)
         StartSizeRange=(X=(Min=60,Max=60),Y=(Min=60,Max=60),Z=(Min=60,Max=60))
         InitialParticlesPerSecond=5000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
         TextureUSubdivisions=8
         TextureVSubdivisions=8
         LifetimeRange=(Min=12.000000,Max=12.000000)
         StartVelocityRange=(X=(Min=-750.000000,Max=750.000000),Y=(Min=-750.000000,Max=750.000000))
         VelocityLossRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000),Z=(Min=10.000000,Max=10.000000))
     End Object
     Emitters(0)=SpriteEmitter'ScrnBalanceSrv.ScrnNadeHealing.SpriteEmitter0'

     AutoDestroy=True
     bNoDelete=False
     RemoteRole=ROLE_None // don't replicate to clients
     bNotOnDedServer=True
}

