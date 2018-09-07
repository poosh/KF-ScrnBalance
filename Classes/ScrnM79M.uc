// Incendiary M79
class ScrnM79M extends M79GrenadeLauncher;

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


    SetBoneScale (56, 0.0, 'Empty_Shell');
    if ( Level.NetMode != NM_DedicatedServer ) {
        FakedNade = spawn(class'ScrnFakedHealingGrenade',self);
        if ( FakedNade != none ) {
            SetBoneRotation('Shell', rot(0, -10100, 0)); //-10240
            SetBoneLocation('Shell', vect(2.0, -0.1, -0.8) );
            // bone must have a size to properly adjust rotation
            SetBoneScale (55, 0.0001, 'Shell');
            AttachToBone(FakedNade, 'Shell');
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
     Weight=3.000000
     //AttachmentClass=Class'ScrnBalanceSrv.ScrnM79MAttachment'
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM79MFire'
     Description="A classic Vietnam era grenade launcher. Modified to launch healing grenades."
     PickupClass=Class'ScrnBalanceSrv.ScrnM79MPickup'
     ItemName="Medic Grenade Launcher"
     SkinRefs(0)="ScrnTex.Weapons.M79M"
     Priority=50
     GroupOffset=12
}
