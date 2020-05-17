class ToiletPaper extends ScrnSecondaryItem;

defaultproperties
{
    TraderInfoTexture=Texture'ScrnTex.HUD.TP'
    ItemName="Toilet Paper"
    Description="Toilet Paper. Rumors say that it somehow helps to survive the Virus Outbreak. Who knows? At least you will die with the clean butt."

    PickupClass=Class'ScrnBalanceSrv.ToiletPaperPickup'
    FireModeClass(0)=Class'ScrnBalanceSrv.ToiletPaperFire'

    // placeholders
    AttachmentClass=Class'KFMod.FragAttachment'
    Mesh=SkeletalMesh'KF_Weapons_Trip.Frag_Trip'
    Skins(0)=Shader'KillingFloorWeapons.Frag_Grenade.FragShader'
}
