class ScrnAxe extends Axe;

simulated function BringUp(optional Weapon PrevWeapon)
{
    super.BringUp(PrevWeapon);

    if (ClientGrenadeState != GN_BringUp && KFPlayerController(Instigator.Controller) != none) {
        KFPlayerController(Instigator.Controller).WeaponPulloutRemark(24);
    }
}

defaultproperties
{
    bIsTier2Weapon=False
    FireModeClass(0)=class'ScrnAxeFire'
    FireModeClass(1)=class'ScrnAxeFireB'
    PickupClass=class'ScrnAxePickup'
    ItemName="Axe SE"

    HudImageRef="KillingFloorHUD.WeaponSelect.axe_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.Axe"
    SelectSoundRef="KF_AxeSnd.Axe_Select"
    MeshRef="KF_Weapons_Trip.Axe_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.melee.axe_cmb"
    BloodyMaterialRef="KF_Weapons_Trip_T.melee.axe_bloody_cmb"
}
