Class ScrnCustomWeaponLink extends LinkedReplicationInfo;

var class <ScrnVeterancyTypes> Perk;
var class <KFWeapon> WeaponClass;
var bool bWeapon, bDiscount, bFire, bFireAlt, bAmmo, bAmmoAlt;
var bool bOverrideDamType, bOverrideDamTypeAlt, bSpecial;
var int  ForcePrice;

var transient bool bInitReplicationReceived;

replication 
{
    reliable if ( Role == ROLE_Authority )
        Perk, WeaponClass, bWeapon, bDiscount, bFire, bFireAlt, bAmmo, bAmmoAlt, 
        bOverrideDamType, bOverrideDamTypeAlt, bSpecial,
		ForcePrice;
}

simulated function PostNetReceive()
{
    super.PostNetReceive();
    // Can PostNetReceive() be called before PostNetBeginPlay() in ut2k4 engine either?
    if ( bInitReplicationReceived && Role < ROLE_Authority ) {
        LoadWeaponBonuses();
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    bInitReplicationReceived = true;

    if ( Role < ROLE_Authority ) {
        LoadWeaponBonuses();
    }
}

simulated function LoadWeaponBonuses() 
{
    local class<WeaponFire> WF;
    local class<KFWeaponDamageType> DT;
    local class<KFWeaponPickup> WP;
    
    if ( Perk == none || WeaponClass == none ) 
        return;
     
    if ( bWeapon )
        Perk.static.ClassAddToArrayUnique(Perk.default.PerkedWeapons, WeaponClass);  
    if ( bSpecial )
        Perk.static.ClassAddToArrayUnique(Perk.default.SpecialWeapons, WeaponClass);  
    if ( bDiscount )
        Perk.static.ClassAddToArrayUnique(Perk.default.PerkedPickups, WeaponClass.default.PickupClass);  
	
	WP = class<KFWeaponPickup>(WeaponClass.default.PickupClass);
	if ( ForcePrice > 0 && WP != none )
		WP.default.Cost = ForcePrice;
    
    // Primary fire
    WF = WeaponClass.default.FireModeClass[0];
    if ( WF != none && WF != Class'KFMod.NoFire' ) {
        if ( bAmmo ) {
            Perk.static.ClassAddToArrayUnique(Perk.default.PerkedAmmo, WF.default.AmmoClass); 
        }    
        if ( bOverrideDamType && Perk.default.DefaultDamageType != none ) {
            //replace weapon perk index
            class<KFWeaponPickup>(WeaponClass.default.PickupClass).default.CorrespondingPerkIndex = Perk.default.PerkIndex; 

            if ( bFire || Perk.default.DefaultDamageTypeNoBonus == none )
                DT = Perk.default.DefaultDamageType;
            else
                DT = Perk.default.DefaultDamageTypeNoBonus;
                
            //overriding damage types to allow leveling up
            if ( WF.default.ProjectileClass != none )
                WF.default.ProjectileClass.default.MyDamageType = DT;
            if ( class<InstantFire>(WF) != none )
                class<InstantFire>(WF).default.DamageType = DT;
        }
        else if ( bFire ) {
            if ( WF.default.ProjectileClass != none )
                Perk.static.ClassAddToArrayUnique(Perk.default.PerkedDamTypes, WF.default.ProjectileClass.default.MyDamageType); 
            if ( class<InstantFire>(WF) != none )
                Perk.static.ClassAddToArrayUnique(Perk.default.PerkedDamTypes, class<InstantFire>(WF).default.DamageType);
        }    
    }
    
    // Alternate Fire
    WF = WeaponClass.default.FireModeClass[1];
    if ( WF != none && WF != Class'KFMod.NoFire' ) {
        if ( bAmmoAlt ) {
            Perk.static.ClassAddToArrayUnique(Perk.default.PerkedAmmo, WF.default.AmmoClass); 
        }    
        if ( bOverrideDamTypeAlt && Perk.default.DefaultDamageType != none ) {
            if ( bFireAlt || Perk.default.DefaultDamageTypeNoBonus == none )
                DT = Perk.default.DefaultDamageType;
            else
                DT = Perk.default.DefaultDamageTypeNoBonus;        
        
            //overriding damage types to allow leveling up
            if ( WF.default.ProjectileClass != none )
                WF.default.ProjectileClass.default.MyDamageType = DT;
            if ( class<InstantFire>(WF) != none )
                class<InstantFire>(WF).default.DamageType = DT;
        }
        else if ( bFireAlt ) {
            if ( WF.default.ProjectileClass != none )
                Perk.static.ClassAddToArrayUnique(Perk.default.PerkedDamTypes, WF.default.ProjectileClass.default.MyDamageType); 
            if ( class<InstantFire>(WF) != none )
                Perk.static.ClassAddToArrayUnique(Perk.default.PerkedDamTypes, class<InstantFire>(WF).default.DamageType);
        }    
    } 

    Log("Custom weapon" @ String(WeaponClass) @ "loaded for " @ String(Perk) @ "perk.", 'ScrnBalance');
}

defaultproperties
{
}
