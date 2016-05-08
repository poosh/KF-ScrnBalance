class ScrnGUIBuyWeaponInfoPanel extends SRGUIBuyWeaponInfoPanel;

var automated 	GUIImage 			ScrnLogo, TourneyLogo;
var localized 	string 				strSecondsPerShot, StrReloadsInDPM, strMeters;
var automated 	GUILabel 			lblDamage, lblDPS, lblDPM, lblRange, lblMag, lblAmmo;
var automated	ScrnGUIWeaponBar 	barDamage, barDPS, barDPM, barRange, barMag, barAmmo;

var automated 	moCheckBox   		ch_FireMode0, ch_FireMode1;


var int TopDamage, TopDPM, TopMag, TopAmmo;
var float TopDPS, TopRange, TopRadius;

var 			GUIBuyable			LastBuyable;


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	super.InitComponent(MyController, MyOwner);
	
	ch_FireMode0.Checked(true);
}

function ResetValues()
{
	TopDamage = 0;
	TopDPM = 0;
	TopMag = 0;
	TopAmmo = 0;
	TopDPS = 0;
	TopRange = 0;
	TopRadius = 0;
}

function float GetBarPct(float Value, float MaxValue)
{
    if ( Value == 0 || MaxValue == 0 )
        return 0.f;
    
    if ( Value ~= MaxValue )
        return 1.0;
        
    return Sqrt(Value) / Sqrt(MaxValue);
}

function LoadStats(GUIBuyable NewBuyable, byte FireMode, optional bool bSetTopValuesOnly)
{
	local KFPlayerReplicationInfo KFPRI;
	local class<KFVeterancyTypes> Perk;
	local class<ScrnVeterancyTypes> ScrnPerk;
	local class<WeaponFire> WF;
	local class<InstantFire> IFClass;
	local class<BaseProjectileFire> ProjFireClass;
	local class<Projectile> ProjClass;
	local class<KFMeleeFire> MeeleeFireClass;
	local class<DamageType> DamType;
	local class<KFWeaponDamageType> KFDamType;
	local int BaseDmg, PerkedValue, Mult;
	local float FireTime, ReloadTime, dmg, range, ammo, MagTime;
	local float PerkBonus;
	local String s;
	local int MagCapacity, MagCount, TotalAmmo;

	// reset values
	if ( !bSetTopValuesOnly ) {
		barDamage.Value = 0;
		barDPS.Value = 0;
		barDPM.Value = 0;
		barRange.Value = 0;
		barMag.Value = 0;
		barAmmo.Value = 0;
	}
	
	if ( NewBuyable == none )
		return;
		
	if ( NewBuyable.ItemWeaponClass == none )
		return; // todo - show armor %
		
	WF = NewBuyable.ItemWeaponClass.default.FireModeClass[FireMode];
	if ( WF == none || WF == class'KFMod.NoFire' )
		return;

	KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
	if ( KFPRI != none ) {
		Perk = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).ClientVeteranSkill;
		ScrnPerk = class<ScrnVeterancyTypes>(Perk);
	}
		
	// magazine
	if ( FireMode == 0 ) {
		MagCapacity = NewBuyable.ItemWeaponClass.default.MagCapacity;
		if ( MagCapacity > 1 ) {
			// vanilla perks require weapon instance to be passed (not the class), 
			// so bonuses can be shown only for ScrN perks
			if ( ScrnPerk != none )
				PerkedValue = MagCapacity * ScrnPerk.Static.GetMagCapacityModStatic(KFPRI, NewBuyable.ItemWeaponClass);
			else
				PerkedValue = MagCapacity;
			TopMag = max(TopMag, PerkedValue);
			if ( !bSetTopValuesOnly ) {
				barMag.High = TopMag;
				barMag.Value = PerkedValue;
				S = string(PerkedValue);
				barMag.SetHighlight(PerkedValue > MagCapacity);
				if ( PerkedValue != MagCapacity ) {
					if ( PerkedValue > MagCapacity )
						S @= "("$string(MagCapacity)$"+"$string(PerkedValue-MagCapacity)$")";
					else
						S @= "("$string(MagCapacity)$string(PerkedValue-MagCapacity)$")";
				}
				barMag.Caption = S;
			}
			MagCapacity = PerkedValue;
			
			//reload
			ReloadTime = NewBuyable.ItemWeaponClass.default.ReloadRate;
			if ( ScrnPerk != none ) {
				PerkBonus = ScrnPerk.Static.GetReloadSpeedModifierStatic(KFPRI, NewBuyable.ItemWeaponClass);
				ReloadTime /= PerkBonus;
				barDPM.SetHighlight(PerkBonus > 1.0001);
			}
			else {
				barDPM.SetHighlight(false);
			}
			if ( NewBuyable.ItemWeaponClass.default.bHoldToReload ) 
				ReloadTime *= MagCapacity; // per-buller reload		
		}
		else {
			ReloadTime = 0.000001;
			barDPM.SetHighlight(false);
		}
	}
	

	
	// total ammo
	TotalAmmo = 0;
	if ( WF.default.AmmoClass != none ) {
		TotalAmmo = WF.default.AmmoClass.default.MaxAmmo;
		if ( Perk != none )
			PerkedValue = TotalAmmo * Perk.Static.AddExtraAmmoFor(KFPRI, WF.default.AmmoClass);
		else
			PerkedValue = TotalAmmo;
		TopAmmo = max(TopAmmo, PerkedValue);
		if ( !bSetTopValuesOnly ) {
			barAmmo.Value = barAmmo.High * GetBarPct(PerkedValue, TopAmmo);
			S = string(PerkedValue);
			barAmmo.SetHighlight(PerkedValue > TotalAmmo);
			if ( PerkedValue != TotalAmmo ) {
				if ( PerkedValue > TotalAmmo )
					S @= "("$string(TotalAmmo)$"+"$string(PerkedValue-TotalAmmo)$")";
				else
					S @= "("$string(TotalAmmo)$string(PerkedValue-TotalAmmo)$")";
			}
			barAmmo.Caption = S;
		}
		TotalAmmo = PerkedValue;
	}
			
	
	IFClass = class<InstantFire>(WF);
	ProjFireClass = class<BaseProjectileFire>(WF);
	ProjClass = WF.default.ProjectileClass;
	MeeleeFireClass = class<KFMeleeFire>(WF);

	// damage
	if ( IFClass != none ) {
		BaseDmg = IFClass.default.DamageMax;
		DamType = IFClass.default.DamageType;
		Mult = WF.default.AmmoPerFire;
	}
	else if ( ProjFireClass != none && ProjClass != none ) {
		BaseDmg = ProjClass.default.Damage;
		DamType = ProjClass.default.MyDamageType;
		Mult = WF.default.AmmoPerFire * ProjFireClass.default.ProjPerFire;
		
		range = ProjClass.default.DamageRadius;
		TopRadius = max(TopRadius, range);
		if ( !bSetTopValuesOnly ) {
			barRange.Value = barRange.High * range/TopRadius;
			barRange.Caption = string(range/50) @ strMeters;
		}			
	}
	else if ( MeeleeFireClass != none ) {
		BaseDmg = MeeleeFireClass.default.MeleeDamage;
		DamType = MeeleeFireClass.default.hitDamageClass;	
		Mult = 1;
		
		range = MeeleeFireClass.default.weaponRange;
		TopRange = max(TopRange, range);
		if ( !bSetTopValuesOnly ) {
			barRange.Value = barRange.High * range/TopRange;
			barRange.Caption = string(range/50) @ strMeters;
		}		
	}
	
	KFDamType = class<KFWeaponDamageType>(DamType);
	if ( KFDamType != none && KFDamType.default.bDealBurningDamage && class<DamTypeMAC10MPInc>(KFDamType) == none )
		BaseDmg *= 1.5; // stupid fire damage multiplier in KFMonster.TakeDamage()
	
	if ( BaseDmg > 0 && Perk != none )
		PerkedValue = Perk.static.AddDamage(KFPRI, none, KFPawn(PlayerOwner().Pawn), BaseDmg, DamType);
	else 
		PerkedValue = BaseDmg;
	
	if ( class<LAWProj>(ProjClass) != none ) {
		// huskgun and flare revolvers deal both impact+fire damage
		if ( class<FlareRevolverProjectile>(ProjClass) != none || class<HuskGunProjectile>(ProjClass) != none ) {
			dmg = class<LAWProj>(ProjClass).default.ImpactDamage;
			BaseDmg += dmg;
			if ( Perk != none )
				PerkedValue += Perk.static.AddDamage(KFPRI, none, KFPawn(PlayerOwner().Pawn), dmg, class<LAWProj>(ProjClass).default.ImpactDamageType); 
			else 
				PerkedValue += dmg; 
		}
	}
		
	if ( Mult == 1 ) {
		s = string(PerkedValue);
	}
	else {
		s = Mult $ "x" $ PerkedValue @ "=" @ PerkedValue*Mult;
		PerkedValue *= Mult;
		BaseDmg *= Mult;
	}
	TopDamage = max(TopDamage, PerkedValue);
	
	if ( !bSetTopValuesOnly ) {
		barDamage.Value = barDamage.High * GetBarPct(PerkedValue, TopDamage);
		barDamage.SetHighlight(PerkedValue > BaseDmg);
		if ( PerkedValue != BaseDmg ) {
			if ( PerkedValue > BaseDmg )
				S @= "("$string(BaseDmg)$"+"$string(PerkedValue-BaseDmg)$")";
			else
				S @= "("$string(BaseDmg)$string(PerkedValue-BaseDmg)$")";
		}
		barDamage.Caption = S;
	}
	BaseDmg = PerkedValue;
	
	
	if ( BaseDmg > 0 ) {
		// DPS
		FireTime = WF.default.FireRate;
		if ( ScrnPerk != none ) {
			PerkBonus = ScrnPerk.Static.GetFireSpeedModStatic(KFPRI, NewBuyable.ItemWeaponClass);
			FireTime /= PerkBonus;
			barDPS.SetHighlight(PerkBonus > 1.0001);
		}
		else {
			barDPS.SetHighlight(false);
		}
		dmg = BaseDmg / FireTime;
		if ( MagCapacity > 1 )
			dmg = fmin(dmg, BaseDmg * float(MagCapacity) / WF.default.AmmoPerFire); // in cases when magazine can be shot faster than 1s
		TopDPS = max(TopDPS, dmg);
		if ( !bSetTopValuesOnly ) {
			barDPS.Value = barDPS.High * GetBarPct(dmg, TopDPS);
			barDPS.Caption = int(dmg) $ "," @ FireTime $ strSecondsPerShot;
		}
		
		// DPM
		MagCount = 0;
		if ( MagCapacity <= 1 ) {
			// no reload = no problem
			ammo = 60.0 / FireTime;
		} 
		else {
			// how long does it takes to shot whole magazine?
			MagTime = MagCapacity * FireTime / WF.default.AmmoPerFire;
			if ( MagTime >= 60.0 )
				ammo = 60.0 / FireTime; // insane magazine that requires > minute to reload
			else if ( MagTime + ReloadTime >= 60.0 )
				ammo = MagCapacity;
			else {
				MagCount = 60.0 / (MagTime + ReloadTime); // how many full magazines we can shoot in a minute?
				if ( TotalAmmo > 0 )
					MagCount = min(MagCount, ceil(float(TotalAmmo) / MagCapacity));
				ammo = MagCount * MagCapacity;
				// how meany bullets we can shoot from last reloaded magazine?
				ammo += (60.0 - MagCount*(MagTime + ReloadTime)) / FireTime;
			}
				
		}
		if ( TotalAmmo > 0 )
			ammo = min(TotalAmmo / WF.default.AmmoPerFire, ammo);
		dmg = ammo * BaseDmg;
		TopDPM = max(TopDPM, dmg);
		if ( !bSetTopValuesOnly ) {
			if ( MagCount == 0 )
				barDPM.SetHighLight(false);
			barDPM.Value = barDPS.High * GetBarPct(dmg, TopDPM);
			S = string(dmg/1000.0) $ "K";
			if ( MagCount > 0 )
				S $= Repl(StrReloadsInDPM, "%r", MagCount);
			barDPM.Caption = S;
		}		
	}
	else if ( !bSetTopValuesOnly ) {
		barDPS.Value = 0;
		barDPM.Value = 0;
	}
}

function Display(GUIBuyable NewBuyable)
{
    local ScrnCustomPRI ScrnPRI;
    
    // just in case
	b_power.SetVisibility(false);
	b_speed.SetVisibility(false);
	b_range.SetVisibility(false);
	ItemPower.SetVisibility(false);
	ItemRange.SetVisibility(false);
	ItemSpeed.SetVisibility(false);    

	LastBuyable = NewBuyable;
	if ( NewBuyable != none ) {
		ItemName.Caption = NewBuyable.ItemName;
		
		ItemImage.Image = NewBuyable.ItemImage;
		ItemImage.SetVisibility(true);
		ScrnLogo.SetVisibility(false);
		TourneyLogo.SetVisibility(false);
		
		WeightLabel.Caption = Repl(Weight, "%i", int(NewBuyable.ItemWeight));
		if ( NewBuyable.bSaleList && !KFPawn(PlayerOwner().Pawn).CanCarry(NewBuyable.ItemWeight) ) {
			WeightLabel.TextColor.R=192;
			WeightLabel.TextColor.G=32;
			WeightLabel.TextColor.B=32;
		}
		else {
			WeightLabel.TextColor.R=175;
			WeightLabel.TextColor.G=176;
			WeightLabel.TextColor.B=158;
		}

    	FavoriteButton.SetVisibility(NewBuyable.bSaleList);
		bFavorited = (NewBuyable.ItemPickupClass!=None && Class'SRClientSettings'.Static.IsFavorite( NewBuyable.ItemPickupClass ));
    	RefreshFavoriteButton();		
		OldPickupClass = NewBuyable.ItemPickupClass;
		ch_FireMode0.SetVisibility(true);
		ch_FireMode1.SetVisibility(true);
		
		
		
		LoadStats(NewBuyable, byte(ch_FireMode1.IsChecked()), false);
		
		barDamage.SetVisibility(barDamage.Value > 0);			
		lblDamage.SetVisibility(barDamage.bVisible);
		barDPS.SetVisibility(barDPS.Value > 0);			
		lblDPS.SetVisibility(barDPS.bVisible);
		barDPM.SetVisibility(barDPM.Value > 0);			
		lblDPM.SetVisibility(barDPM.bVisible);
		barRange.SetVisibility(barRange.Value > 0);			
		lblRange.SetVisibility(barRange.bVisible);
		barMag.SetVisibility(barMag.Value > 0);			
		lblMag.SetVisibility(barMag.bVisible);
		barAmmo.SetVisibility(barAmmo.Value > 0);			
		lblAmmo.SetVisibility(barAmmo.bVisible);		
	}
	else {
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PlayerOwner().PlayerReplicationInfo);
        if ( ScrnPRI != none && ScrnPRI.IsTourneyMember() ) {
            ItemName.Caption = "Trophy Shop";
            TourneyLogo.SetVisibility(true);
            ScrnLogo.SetVisibility(false);
        }
        else {
            ItemName.Caption = "ScrN Shop";
            ScrnLogo.SetVisibility(true);
            TourneyLogo.SetVisibility(false);
        }
		
		ItemImage.SetVisibility(false);
		FavoriteButton.SetVisibility(false);
		FavoriteButton.SetVisibility(false);
        WeightLabel.Caption = "";
		ch_FireMode0.SetVisibility(false);
		ch_FireMode1.SetVisibility(false);
		
		lblDamage.SetVisibility(false);
		barDamage.SetVisibility(false);		
		lblDPS.SetVisibility(false);
		barDPS.SetVisibility(false);		
		lblDPM.SetVisibility(false);
		barDPM.SetVisibility(false);		
		lblRange.SetVisibility(false);
		barRange.SetVisibility(false);
		lblMag.SetVisibility(false);
		barMag.SetVisibility(false);
		lblAmmo.SetVisibility(false);
		barAmmo.SetVisibility(false);
	}
}

function FireModeChange(GUIComponent Sender)
{
	if ( ch_FireMode1.IsChecked() == ch_FireMode0.IsChecked() ) {
		if ( Sender == ch_FireMode0 )
			ch_FireMode1.Checked(!ch_FireMode0.IsChecked());
		else if ( Sender == ch_FireMode1 )
			ch_FireMode0.Checked(!ch_FireMode1.IsChecked());
            
		if ( ScrnTab_BuyMenu(MenuOwner) != none )
			Display(ScrnTab_BuyMenu(MenuOwner).TheBuyable);
		else
			Display(LastBuyable);
	}
}


defaultproperties
{
     Begin Object Class=GUIImage Name=IImage
         ImageStyle=ISTY_Justified
         WinTop=0.09
         WinLeft=0.20
         WinWidth=0.60
         WinHeight=0.574359
         bBoundToParent=True
         bScaleToParent=True
		 RenderWeight=2.000000
     End Object
     ItemImage=GUIImage'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.IImage'
	 
     Begin Object Class=GUIImage Name=ILogo
		Image=texture'ScrnTex.HUD.ScrNBalanceLogo256'
		ImageColor=(B=255,G=255,R=255,A=64)
         ImageStyle=ISTY_Scaled
         WinTop=0.15
         WinLeft=0.15
         WinWidth=0.70
         WinHeight=0.85
         bBoundToParent=True
         bScaleToParent=True
		 RenderWeight=1.000000
     End Object
     ScrnLogo=GUIImage'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.ILogo'
     
     Begin Object Class=GUIImage Name=TSCLogo
		Image=Texture'ScrnTex.Tourney.TourneyMember' 
		ImageColor=(B=255,G=255,R=255,A=255)
         ImageStyle=ISTY_Scaled
         WinTop=0.15
         WinLeft=0.15
         WinWidth=0.70
         WinHeight=0.85
         bBoundToParent=True
         bScaleToParent=True
		 RenderWeight=2.000000
         bVisible=False
     End Object
     TourneyLogo=GUIImage'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.TSCLogo'     

     Begin Object Class=GUIImage Name=LWeightBG
         //Image=Texture'KF_InterfaceArt_tex.Menu.Innerborder_transparent'
         Image=none
         ImageStyle=ISTY_Normal
         WinTop=0
         WinLeft=0
         WinWidth=0.00
         WinHeight=0.00
		 bVisible=False
     End Object
     WeightLabelBG=GUIImage'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.LWeightBG'

     Begin Object Class=GUILabel Name=LWeight
         TextAlign=TXTA_Right
         VertAlign=TXTA_Left // top
         TextColor=(B=158,G=176,R=175)
         TextFont="UT2LargeFont"
		 FontScale=FNS_Medium
         WinTop=0.11
         WinLeft=0.05
         WinWidth=0.90
         WinHeight=0.10
         bBoundToParent=True
         bScaleToParent=True
         bNeverFocus=True
		 RenderWeight=3
     End Object
     WeightLabel=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.LWeight'
     Weight="%i blocks"
	 
     Begin Object Class=moCheckBox Name=Mode0Check
		CaptionWidth=0.95
		OnCreateComponent=Mode0Check.InternalOnCreateComponent
		bAutoSizeCaption=True
		Caption="Primary Fire"
		Hint="Show primary fire stats"
		WinTop=0.500000
		WinLeft=0.05
		WinWidth=0.40
		TabOrder=0
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
		IniOption="@Internal"
		OnChange=ScrnGUIBuyWeaponInfoPanel.FireModeChange
		RenderWeight=3
		bBoundToParent=True
		bScaleToParent=True	
		bVisible=False		
     End Object
     ch_FireMode0=moCheckBox'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.Mode0Check'	 
	 
     Begin Object Class=moCheckBox Name=Mode1Check
		CaptionWidth=0.95
		OnCreateComponent=Mode1Check.InternalOnCreateComponent
		bFlipped=True
		Caption="Secondary Fire"
		Hint="Show secondary (alternate) fire stats"
		WinTop=0.500000
		WinLeft=0.50
		WinWidth=0.40
		TabOrder=1
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
		IniOption="@Internal"
		OnChange=ScrnGUIBuyWeaponInfoPanel.FireModeChange
		RenderWeight=3
         bBoundToParent=True
         bScaleToParent=True		
		bVisible=False
     End Object
     ch_FireMode1=moCheckBox'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.Mode1Check'	 



	Begin Object Class=GUILabel Name=DamageCap
		Caption="Damage:"
		Hint="Weapon actual damage, including perk bonus"
		TextColor=(B=158,G=176,R=175)
		TextAlign=TXTA_Left
		VertAlign=TXTA_Center		
		TextFont="UT2SmallFont"
		FontScale=FNS_Medium
		WinTop=0.58
		WinLeft=0.05
		WinWidth=0.25
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	lblDamage=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.DamageCap'	
	
	Begin Object Class=ScrnGUIWeaponBar Name=DamageBar
		Hint="Weapon damage"
		BorderSize=3.000000
		WinTop=0.58
		WinLeft=0.30
		WinWidth=0.65
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	barDamage=ScrnGUIWeaponBar'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.DamageBar'	 
	
	
	Begin Object Class=GUILabel Name=DPSCap
		Caption="per second:"
		Hint="Damage per second"
		TextColor=(B=158,G=176,R=175)
		TextAlign=TXTA_Left
		VertAlign=TXTA_Center		
		TextFont="UT2SmallFont"
		FontScale=FNS_Medium
		WinTop=0.65
		WinLeft=0.07
		WinWidth=0.23
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	lblDPS=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.DPSCap'	
	
	Begin Object Class=ScrnGUIWeaponBar Name=DPSBar
		Hint="Damage per second or magazine (if able to shoot whole magazine"
		BorderSize=3.000000
		WinTop=0.65
		WinLeft=0.30
		WinWidth=0.65
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	barDPS=ScrnGUIWeaponBar'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.DPSBar'	
	strSecondsPerShot="s/shot"
	
	Begin Object Class=GUILabel Name=DPMCap
		Caption="per minute:"
		Hint="Damage per minute, including reloads"
		TextColor=(B=158,G=176,R=175)
		TextAlign=TXTA_Left
		VertAlign=TXTA_Center		
		TextFont="UT2SmallFont"
		FontScale=FNS_Medium
		WinTop=0.72
		WinLeft=0.07
		WinWidth=0.23
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	lblDPM=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.DPMCap'	
	
	Begin Object Class=ScrnGUIWeaponBar Name=DPMBar
		Hint="Damage per minute, including reloads"
		BorderSize=3.000000
		WinTop=0.72
		WinLeft=0.30
		WinWidth=0.65
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	barDPM=ScrnGUIWeaponBar'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.DPMBar'	
	StrReloadsInDPM=", incl. %r reloads"

	
	Begin Object Class=GUILabel Name=RangeCap
		Caption="Range:"
		Hint="Weapon range (for melee weapons) or blast radius (for explosives and fire)"
		TextColor=(B=158,G=176,R=175)
		TextAlign=TXTA_Left
		VertAlign=TXTA_Center		
		TextFont="UT2SmallFont"
		FontScale=FNS_Medium
		WinTop=0.79
		WinLeft=0.05
		WinWidth=0.25
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	lblRange=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.RangeCap'	
	
	Begin Object Class=ScrnGUIWeaponBar Name=RangeBar
		Hint="Weapon range (for melee weapons) or blast radius (for explosives and fire)"
		BorderSize=3.000000
		WinTop=0.79
		WinLeft=0.30
		WinWidth=0.65
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	barRange=ScrnGUIWeaponBar'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.RangeBar'
	strMeters="meters"
	
	
	Begin Object Class=GUILabel Name=MagCap
		Caption="Magazine:"
		Hint="Ammo count in magazine"
		TextColor=(B=158,G=176,R=175)
		TextAlign=TXTA_Left
		VertAlign=TXTA_Center		
		TextFont="UT2SmallFont"
		FontScale=FNS_Medium
		WinTop=0.86
		WinLeft=0.05
		WinWidth=0.25
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	lblMag=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.MagCap'	
	
	Begin Object Class=ScrnGUIWeaponBar Name=MagBar
		Hint="Ammo count in magazine"
		BorderSize=3.000000
		WinTop=0.86
		WinLeft=0.30
		WinWidth=0.65
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	barMag=ScrnGUIWeaponBar'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.MagBar'	
	
	
	Begin Object Class=GUILabel Name=AmmoCap
		Caption="Total Ammo:"
		Hint="Total amount of ammo that can be carried for this weapon"
		TextColor=(B=158,G=176,R=175)
		TextAlign=TXTA_Left
		VertAlign=TXTA_Center		
		TextFont="UT2SmallFont"
		FontScale=FNS_Medium
		WinTop=0.93
		WinLeft=0.05
		WinWidth=0.25
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object
	lblAmmo=GUILabel'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.AmmoCap'	
	
	Begin Object Class=ScrnGUIWeaponBar Name=AmmoBar
		Hint="Total amount of ammo that can be carried for this weapon"
		BorderSize=3.000000
		WinTop=0.93
		WinLeft=0.30
		WinWidth=0.65
		WinHeight=0.055
		bBoundToParent=True
		bScaleToParent=True
		bVisible=False
	End Object	
	barAmmo=ScrnGUIWeaponBar'ScrnBalanceSrv.ScrnGUIBuyWeaponInfoPanel.AmmoBar'	
}