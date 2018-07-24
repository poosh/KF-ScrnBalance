class ScrnFlameNadeTrail extends ReducedGrenadeTrail;

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
         ColorScale(0)=(Color=(B=60,G=225,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=225,R=255,A=255))
     End Object
     Emitters(0)=SpriteEmitter'ScrnBalanceSrv.ScrnFlameNadeTrail.SpriteEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         ColorScale(0)=(Color=(B=60,G=100,R=120,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=120,G=200,R=240,A=255))
     End Object
     Emitters(1)=SpriteEmitter'ScrnBalanceSrv.ScrnFlameNadeTrail.SpriteEmitter1'
}
