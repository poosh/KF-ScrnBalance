class ToiletPaper extends ScrnSecondaryItem;

defaultproperties
{
    TraderInfoTexture=Texture'ScrnTex.HUD.TP'
    HudImage=Texture'ScrnTex.HUD.TP'
    SelectedHudImage=Texture'ScrnTex.HUD.TP'

    ItemName="Toilet Paper"
    Description="Toilet Paper. Rumors say that it somehow helps to survive the Virus Outbreak. Who knows? At least you will die with the clean butt."

    PickupClass=class'ToiletPaperPickup'
    FireModeClass(0)=class'ToiletPaperFire'

    // placeholders
    AttachmentClass=Class'KFMod.FragAttachment'
    Mesh=SkeletalMesh'KF_Weapons_Trip.Frag_Trip'
    Skins(0)=Shader'KillingFloorWeapons.Frag_Grenade.FragShader'
}
