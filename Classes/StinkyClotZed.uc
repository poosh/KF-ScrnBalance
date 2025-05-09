// Zed (enemy) version of Stinky Clot
// Extended from ZombieClotMix to allow blocking Stinky paths
// by adding Class'ZombieClotMix' to BlockingVolume.BlockedClasses
class StinkyClotZed extends ZombieClotMix;

simulated function BeginPlay()
{
	Super(ZombieClot).BeginPlay();
}

defaultproperties
{
    MenuName="Evil Stinky Clot"
    EventClasses(0)="ScrnBalanceSrv.StinkyClotZed"
    ControllerClass=Class'KFMod.KFMonsterController'

    bUseExtendedCollision=false
    ColOffset=(X=5,Z=25)
    ColRadius=12
    ColHeight=3

    DrawScale=0.5
    CollisionRadius=18
    CollisionHeight=24
    PrePivot=(X=0,Y=0,Z=0)
    HeadRadius=4
    OnlineHeadshotOffset=(X=9,Z=16)
    OnlineHeadshotScale=1.5

    GroundSpeed=42
    Health=1000
    HealthMax=1000
    HeadHealth=1000
    JumpZ=340

    MoanVoice=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmClot'
    DetachedLegClass=Class'KFChar.SeveredLegClot'
    DetachedHeadClass=Class'KFChar.SeveredHeadClot'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    AmbientSound=Sound'KF_BaseClot.Clot_Idle1Loop'
    Mesh=SkeletalMesh'KF_Freaks_Trip.CLOT_Freak'
    Skins(0)=Combiner'KF_Specimens_Trip_T.clot_cmb'
    Skins(1)=none
    KFRagdollName="Clot_Trip"
}
