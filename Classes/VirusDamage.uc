class VirusDamage extends DamTypeZombieAttack;

#exec OBJ LOAD FILE=ScrnTex.utx

defaultproperties
{
    HUDDamageTex=ColorModifier'ScrnTex.HUD.VirusOverlay'
    HUDUberDamageTex=ColorModifier'ScrnTex.HUD.VirusOverlay'
    HUDTime=5.500000
    bArmorStops=false
    bLocationalHit=false
    bCheckForHeadShots=false
    DeathString="%o died from The Virus."
    FemaleSuicide="%o died from the Virus."
    MaleSuicide="%o died from the Virus."
}
