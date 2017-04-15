class StinkyClot extends ZombieClot;

var() name CompleteAnim;
var() name GrabBone;


simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    SetSkin();
}

simulated event PostNetReceive()
{
    super.PostNetReceive();
    SetSkin();
}

simulated function SetSkin()
{
    if ( bBlockActors ) {
        Skins[0] = default.Skins[0];
        if ( bCrispified )
            ZombieCrispUp();
    }
    else {
        Skins[0] = ColorModifier'ScrnTex.Zeds.StinkyColor';
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType, optional int HitIndex )
{
    if ( bBlockActors )
        super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType, HitIndex);
    // stinky clot does not take damage
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local int i;
    local TheGuardian gnome;

 	for( i=0; i<Attached.length; i++ ) {
        gnome = TheGuardian(Attached[i]);
        if ( gnome != none )
            gnome.PawnBaseDied();
	}

    super.Died(Killer,damageType,HitLocation);
}


function bool FlipOver()
{
    return false;
}

function RemoveHead()
{
    KilledBy(LastDamagedBy);
}

// removed references to KFMonsterController
event Bump(actor Other)
{
    if ( KFDoorMover(Other) != none )
        BlowUpDoor(KFDoorMover(Other));
    else
        super(Monster).Bump(Other);
}

function BlowUpDoor(KFDoorMover door)
{
    local int i;
    local KFUseTrigger key;

    if ( door == none || !door.bClosed )
        return;

    key = door.MyTrigger;
    if ( key != none ) {
        for ( i=0; i<key.DoorOwners.Length; ++i ) {
            if ( !key.DoorOwners[i].bDoorIsDead )
                key.DoorOwners[i].GoBang(self, Location, vector(Rotation), none);
        }
    }
    else
        door.GoBang(self, Location, vector(Rotation), none);
}

function KickActor()
{
    // no KFMonsterController to perform a kick
}


simulated function SetBurningBehavior()
{
}

simulated function UnSetBurningBehavior()
{
}

simulated function float GetOriginalGroundSpeed()
{
    return GroundSpeed;
}


defaultproperties
{
    MenuName="Stinky Clot"
    EventClasses(0)="ScrnBalanceSrv.StinkyClot"

    ControllerClass=Class'ScrnBalanceSrv.StinkyController'
    CompleteAnim="ClotPunt"
    GrabBone="CHR_RArmPalm"

    bAlwaysRelevant=true
    bUseExtendedCollision=false
    DrawScale=0.5
    CollisionRadius=13
    CollisionHeight=22
    bBlockActors=false
    GroundSpeed=55
    Health=1000
    HealthMax=1000
    HeadHealth=1000

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
}