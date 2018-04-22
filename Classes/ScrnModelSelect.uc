class ScrnModelSelect extends SRModelSelect;

function bool IsUnlocked(xUtil.PlayerRecord Test)
{
    local ScrnPlayerController PC;
    
    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return true;
    
    // dunno why but Mrs.Foster dosn't pass super.IsUnlocked()
    return PC.IsTeamCharacter(Test.DefaultName) && 
        (Test.DefaultName ~= "Mrs_Foster" 
            || Test.DefaultName ~= "Ms_Clamley" 
            || super.IsUnlocked(Test)); 
}


