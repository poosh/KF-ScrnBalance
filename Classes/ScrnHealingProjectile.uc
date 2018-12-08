class ScrnHealingProjectile extends HealingProjectile;

simulated function PostNetReceive()
{
    if( bHidden && !bHitHealTarget )
    {
        if( HealLocation != vect(0,0,0) )
        {
            // log("PostNetReceive calling HitHealTarget for location of "$HealLocation);
            HitHealTarget(HealLocation,vector(HealRotation));
        }
        // HealLocation doesn't received from server, so don't call HitHealTarget
        // Actually PostNetReceive() shouldn't be called without HealLocation, but who knows
        // the devil that is living inside KF code? :)
        // (c) PooSH
        /*
        else
        {
            log("PostNetReceive calling HitHealTarget for self location of "$HealLocation);
            HitHealTarget(Location,-vector(Rotation));
        }
        */
    }
}

//copy-pasted to use GiveHealth()
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local KFPlayerReplicationInfo PRI;
    local int MedicReward;
    local KFHumanPawn Healed;
    local float HealSum; // for modifying based on perks
    local float HealPotency;

    if ( Other == none || Other == Instigator || Other.Base == Instigator )
        return;

    // KFBulletWhipAttachment is attached to KFPawns
    if ( ROBulletWhipAttachment(Other) != none ) {
        Healed = KFHumanPawn(Other.Owner);
        if ( Healed == none || Healed.Health >= Healed.HealthMax )
            return;
    }
    else
        Healed = KFHumanPawn(Other);

    if( Healed != none ) {
        if( Role == ROLE_Authority ) {
            // server side
            HitHealTarget(HitLocation, -vector(Rotation));

            if( Instigator != none && Healed.Health > 0 && Healed.Health <  Healed.HealthMax ) {
                PRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
                HealPotency = 1.0;

                if ( PRI != none && PRI.ClientVeteranSkill != none )
                    HealPotency = PRI.ClientVeteranSkill.Static.GetHealPotency(PRI);

                MedicReward = HealBoostAmount * HealPotency;
                HealSum = MedicReward;

                if ( (Healed.Health + Healed.healthToGive + MedicReward) > Healed.HealthMax ) {
                    MedicReward = max(0, Healed.HealthMax - (Healed.Health + Healed.healthToGive));
                }

                if ( Healed.Controller != none )
                    Healed.Controller.ShakeView(ShakeRotMag, ShakeRotRate, ShakeRotTime, ShakeOffsetMag, ShakeOffsetRate, ShakeOffsetTime);

                if ( ScrnHumanPawn(Healed) != none )
                    ScrnHumanPawn(Healed).TakeHealing(ScrnHumanPawn(Instigator), HealSum, HealPotency, KFWeapon(Instigator.Weapon));
                else
                    Healed.GiveHealth(HealSum, Healed.HealthMax);

                if ( PRI != None ) {
                    if ( MedicReward > 0 && KFSteamStatsAndAchievements(PRI.SteamStatsAndAchievements) != none )
                        KFSteamStatsAndAchievements(PRI.SteamStatsAndAchievements).AddDamageHealed(MedicReward,
                            MP7MMedicGun(Instigator.Weapon) != none, MP5MMedicGun(Instigator.Weapon) != none);

                    // Give the medic reward money as a percentage of how much of the person's health they healed
                    MedicReward = int((FMin(float(MedicReward),Healed.HealthMax)/Healed.HealthMax) * 60.0); // Increased to 80 in Balance Round 6, reduced to 60 in Round 7

                    if ( class'ScrnBalance'.default.Mut.bMedicRewardFromTeam && Healed.PlayerReplicationInfo != none && Healed.PlayerReplicationInfo.Team != none ) {
                        // give money from team wallet
                        if ( Healed.PlayerReplicationInfo.Team.Score >= MedicReward ) {
                            Healed.PlayerReplicationInfo.Team.Score -= MedicReward;
                            PRI.Score += MedicReward;
                        }
                    }
                    else
                        PRI.Score += MedicReward;

                    // Don't reward team with healing money  --  PooSH
                    //PRI.Team.Score += MedicReward;


                    if ( KFHumanPawn(Instigator) != none )
                    {
                        KFHumanPawn(Instigator).AlphaAmount = 255;
                    }

                    ClientSuccessfulHeal(Healed.GetPlayerName());
                }
            }
        }
        else {
            // client side
            bHidden = true;
            SetPhysics(PHYS_None);
            SetTimer(2.0, false); //give server some time to tell us we're healed somebody, or destroy
            return;
        }
    }
    Explode(HitLocation,-vector(Rotation));
}

function ClientSuccessfulHeal(String PlayerName)
{
    if( KFMedicGun(Instigator.Weapon) != none )
        KFMedicGun(Instigator.Weapon).ClientSuccessfulHeal(PlayerName);
}

simulated function Timer()
{
    if ( Role == ROLE_Authority)
        super.Timer();
    else if ( !bHitHealTarget ) // Didn't receive HealingLocation from the Server - Destoy
        Destroy();
}

// why need to shake nearby players?
function ShakeView()
{
}


defaultproperties
{
    Damage=0
    DamageRadius=0
}
