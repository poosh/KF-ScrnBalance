class ScrnDamTypeFlare extends DamTypeFlareRevolver
    abstract;

var int MinBurnTime; // minimum/initial time in seconds from ignition till the end of burning
var float BurnTimeInc; // increase of burn time per flare (MinBurnTime + BurnTimeInc*FlareCount)
var int MaxBurnTime; // maximum burning time that can be reached with FlareCount * BurnTimeInc
var int BurnTimeBoost; // boost the current burn time, if zed was already burning. BurnTimeBoost is applied before the MinBurnTime.

// iDoT_FadeFactor sets how fast incremental Damage over Time fades out, making each subsequent flare add less damage.
// The higher iDoT_FadeFactor the less damage subsequent flares add to the iDoT.
// iDoT_FadeFactor=0 - no fade; each flare adds full damage to iDoT.
// iDoT_FadeFactor=1 - double fade; each flare adds twice less damage to iDoT
// iDoT_FadeFactor=0.25 - 25% fade.
var float iDoT_FadeFactor;
// iDoT_MinBoostRation doesn't allow iDoT_FadeFactor to drop iDoT boost below the certain % of the incoming damage.
var float iDoT_MinBoostRatio;


defaultproperties
{
     WeaponClass=Class'ScrnBalanceSrv.ScrnFlareRevolver'
     DeathString="%k burned %o."
     FemaleSuicide="%o burned down."
     MaleSuicide="%o burned down."

     MinBurnTime=6
     MaxBurnTime=12
     BurnTimeInc=0.5
     BurnTimeBoost=2
     iDoT_FadeFactor=0.25
     iDoT_MinBoostRatio=0.20
}
