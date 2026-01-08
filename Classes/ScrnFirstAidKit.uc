class ScrnFirstAidKit extends FirstAidKit;

var() int HealBoost;
var localized string ItemName;

var transient float NextMsgTime;

function bool HealPawn(Pawn Healed)
{
    if (Healed.Health <= 0)
        return false;

    if (HealBoost <= 0)
        return Healed.GiveHealth(HealingAmount, GetHealMax(Healed));

    Healed.Health += HealBoost;
    Healed.GiveHealth(HealingAmount, GetHealMax(Healed));
    return true;
}

auto state Pickup
{
    function Touch( actor Other ) {
        local Pawn P;

        P = Pawn(Other);
        if (P == none || !ValidTouch(Other))
            return;

        if (HealPawn(P)) {
            AnnouncePickup(P);
            SetRespawn();
        }
        else if (Level.TimeSeconds > NextMsgTime && PlayerController(P.Controller) != none) {
            PlayerController(P.Controller).ClientMessage("You are already at full health.", 'KFCriticalEvent');
            NextMsgTime = Level.TimeSeconds + 1.0;
        }
    }
}

defaultproperties
{
    HealingAmount=50
    HealBoost=50
    ItemName="Medkit"
}
