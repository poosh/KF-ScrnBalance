class TSCClanReplicationInfo extends ReplicationInfo
dependson(ScrnHUD);

var TSCClanInfo Clan;

var string Acronym;
var string ClanName;
var string DecoName; // decorated name with colors and line breaks
var Material Logo;
var Material Banner;

replication
{
    reliable if (bNetInitial && Role==ROLE_Authority)
        Acronym, ClanName, DecoName, Logo, Banner;
}

static function TSCClanReplicationInfo FindAndCreate(Actor Owner, string Acronym)
{
    local TSCClanInfo Clan;

    // must be created on server-side onlyl then replicated to clients
    if (Owner == none || Owner.Level.NetMode == NM_Client)
        return none;

    Clan = new(none, Acronym) class'TSCClanInfo';
    if (Clan.Acronym == "") {
        warn("Clan '" $ Acronym $ "' does not exist in the config");
        return none;
    }

    return Create(Owner, Clan);
}

static function TSCClanReplicationInfo Create(Actor Owner, TSCClanInfo Clan)
{
    local TSCClanReplicationInfo rep;

    if (Clan == none)
        return none;

    rep = Owner.spawn(class'TSCClanReplicationInfo', Owner);
    rep.Clan = Clan;
    rep.Acronym = Clan.Acronym;
    rep.ClanName = Clan.ClanName;
    rep.LoadAssets();
    return rep;
}

simulated function PostNetBeginPlay()
{
    if (Level.NetMode != NM_Client)
        return;

    Clan = new(none, Acronym) class'TSCClanInfo';
    // Clan acronym and name must match between server and clients.
    // Other (cosmetic) fields can be configured client-side
    Clan.Acronym = Acronym;
    Clan.ClanName = ClanName;
    LoadAssets();
}

simulated function LoadAssets()
{
    if (Clan == none)
        return;

    Clan.ClanName = class'ScrnFunctions'.static.StripColorTags(Clan.ClanName);
    Clan.ClanName = class'ScrnFunctions'.static.StripColor(Clan.ClanName);

    if (Clan.DecoName != "") {
        DecoName = class'ScrnFunctions'.static.ParseColorTags(Clan.DecoName);
    }

    if (Clan.LogoRef != "") {
        Logo = Material(DynamicLoadObject(Clan.LogoRef, class'Material'));
        // if (Logo != none && Logo.MaterialUSize() != Logo.MaterialVSize()) {
        //     warn("Clan logo must be of squad size! '" $ Clan.LogoRef $ "' is "
        //             $ Logo.MaterialUSize() $ "x" $ Logo.MaterialVSize());
        //     Logo = none;
        // }
    }

    if (Clan.BannerRef != "") {
        Banner = Material(DynamicLoadObject(Clan.BannerRef, class'Material'));
        // if (Banner != none && Banner.MaterialUSize() != 2 * Banner.MaterialVSize())  {
        //     warn("Clan banner size must be 2:1! '" $ Clan.BannerRef $ "' is "
        //             $ Banner.MaterialUSize() $ "x" $ Banner.MaterialVSize());
        //     Banner = none;
        // }
    }
}


defaultproperties
{
    NetUpdateFrequency=1.0
}