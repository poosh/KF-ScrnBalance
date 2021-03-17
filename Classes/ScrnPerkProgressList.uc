class ScrnPerkProgressList extends SRPerkProgressList;

function string AddCommas(int Value)
{
    local string R, L;

    L = string(Value);
    while ( Len(L) > 3 ) {
        R = UnitDelimiter $ Right(L, 3) $ R;
        L = Left(L, Len(L) - 3);
    }
    return L $ R;
}

// KF1 engine does not have operator int % (int, int), only the float version.
// Hence "i1 % i2" triggers operator float(i1) % float(i2) and may cause precision errors
function string FormatNumber(int Value)
{
    local int m;

    if ( Value < 100000 ){
        // Anything less than 100,000 needs no formatting
        return string(Value);
    }

    if ( Value < 1000000 ) {
        // Anything between 100,000 and 1 million turns into ___K
        return string(Value / 1000) $ OneThousandSuffix;
    }

    // Anything over 1 million turns into _._M
    m = Value / 1000000;
    Value -= m * 1000000;
    return string(m) $ DecimalPoint $ string(Value / 100000) $ OneMillionSuffix;
}

defaultproperties
{
}
