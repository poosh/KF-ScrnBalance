class ScrnM4203MMedicGun extends ScrnM4203AssaultRifle
    config(user);


var localized   string  SuccessfulHealMessage;

var ScrnFakedHealingGrenade FakedNade;

replication
{
     reliable if( Role == ROLE_Authority )
        ClientSuccessfulHeal;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( Level.NetMode != NM_DedicatedServer ) {
        SetBoneScale (58, 0.0, 'M203_EmptyShell');

        FakedNade = spawn(class'ScrnFakedHealingGrenade',self);
        if ( FakedNade != none ) {
            SetBoneRotation('M203_Round', rot(0, 6000, 0));
            // bone must have a size to properly adjust rotation
            SetBoneScale (59, 0.0001, 'M203_Round');
            AttachToBone(FakedNade, 'M203_Round');
        }
    }
}


simulated function Destroyed()
{
    if ( FakedNade != None )
        FakedNade.Destroy();
    super.Destroyed();
}

// The server lets the client know they successfully healed someone
simulated function ClientSuccessfulHeal(int HealedPlayerCount, int HealedAmount)
{
    local string str;

    if( PlayerController(Instigator.Controller) != none ) {
        str = SuccessfulHealMessage;
        ReplaceText(str, "%c", String(HealedPlayerCount));
        ReplaceText(str, "%a", String(HealedAmount));

        PlayerController(Instigator.controller).ClientMessage(str, 'CriticalEvent');
    }
}

defaultproperties
{
     SuccessfulHealMessage="You healed %c player(-s) with %ahp"
     bIsTier2Weapon=False
     bIsTier3Weapon=True
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM4203MBulletFire'
     FireModeClass(1)=Class'ScrnBalanceSrv.ScrnM203MFire'
     Description="An assault rifle with an attached healing grenade launcher. Shoots in 3-bullet fixed-burst mode."
     InventoryGroup=4
     PickupClass=Class'ScrnBalanceSrv.ScrnM4203MPickup'
     ItemName="M4-203M Medic Rifle"
     SkinRefs(0)="ScrnTex.Weapons.M4203M"
     Priority=70 // to switch after MP5M
     //PrePivot=(Z=-0.35) //rotational fix for ironsight alignment
     //PlayerViewPivot=(Pitch=30,Roll=0,Yaw=5) //correction of sight position after rotation fix
}
