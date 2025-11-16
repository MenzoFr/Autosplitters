state("HelloNeighbor-Win64-Shipping", "Epic Games")
{
    int startStatus: 0x02FA4B90, 0xD00;
    int menuStatus: 0x02FA4B90, 0x880, 0x6F8;
    float playerBase: 0x02FA4B90, 0x0;
    float XCoord: 0x02FA4B90, 0x158, 0x194;
    float YCoord: 0x02FA4B90, 0x158, 0x198;
    float ZCoord: 0x02FA4B90, 0x158, 0x190;
}

state("HelloNeighbor-Win64-Shipping", "Steam")
{
    int startStatus: 0x02D3EAD0, 0xD00;
    int menuStatus: 0x02D3EAD0, 0x880, 0x6F8;
    float playerBase: 0x02D3EAD0, 0x0;
    float XCoord: 0x02D3EAD0, 0x158, 0x194;
    float YCoord: 0x02D3EAD0, 0x158, 0x198;
    float ZCoord: 0x02D3EAD0, 0x158, 0x190;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Hello Neighbor: Hide and Seek";
    vars.Helper.AlertLoadless();
    
    vars.uharaInitialized = false;
    
    settings.Add("recommendedSplits", true, "Recommended Splits");
    settings.Add("useRecommendedSplits", false, "Use recommended splits (Any%)", "recommendedSplits");
    vars.lastSplitsSetting = false;
}

init
{
    version = "";
    
    switch (modules.First().ModuleMemorySize)
    {
        case 55885824:
            version = "Epic Games";
            break;
        case 53239808:
            version = "Steam";
            break;
        default:
            version = "Unknown";
            break;
    }
    
    if (version == "Unknown")
    {
        throw new Exception("Unknown game version. Module size: " + modules.First().ModuleMemorySize);
    }
    
    IntPtr gSync = vars.Helper.ScanRel(5, "89 43 60 8B 05 ?? ?? ?? ??");

    if (gSync == IntPtr.Zero)
    {
        const string Msg = "Not all required addresses could be found by scanning.";
        throw new Exception(Msg);
    }

    vars.Helper["GSync"] = vars.Helper.Make<bool>(gSync);
    
    vars.currentWorld = "";
    vars.oldWorld = "";
    vars.split = 0;
    
    try
    {
        Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
        vars.Uhara.EnableDebug();
        vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
        vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
        vars.uharaInitialized = true;
    }
    catch
    {
        vars.uharaInitialized = false;
    }
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();
    
    if (settings["useRecommendedSplits"] != vars.lastSplitsSetting)
    {
        if (settings["useRecommendedSplits"])
        {
            timer.Run.Clear();
            timer.Run.CategoryName = "Any%";
            timer.Run.Add(new LiveSplit.Model.Segment("Stage 1"));
            timer.Run.Add(new LiveSplit.Model.Segment("Stage 2"));
            timer.Run.Add(new LiveSplit.Model.Segment("Stage 3"));
            timer.Run.Add(new LiveSplit.Model.Segment("Stage 4"));
            timer.Run.Add(new LiveSplit.Model.Segment("Stage 5"));
        }
        vars.lastSplitsSetting = settings["useRecommendedSplits"];
    }
    
    if (vars.uharaInitialized)
    {
        var uharaOk = false;
        try
        {
            if (vars.Uhara != null)
            {
                vars.Uhara.Update();
                uharaOk = true;
            }
        }
        catch
        {
            uharaOk = false;
        }

        if (!uharaOk || vars.Utils == null)
        {
            try
            {
                vars.Uhara = Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
                try { vars.Uhara.EnableDebug(); } catch {}
                vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
                try { vars.Resolver.Clear(); } catch {}
                vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
                
                vars.split = 0;
                vars.currentWorld = "";
                vars.oldWorld = "";
            }
            catch
            {
                return;
            }
        }
        
        vars.oldWorld = vars.currentWorld;

        var worldNameIndex = vars.Resolver["GWorldName"].Current;
        var world = vars.Utils.FNameToStringLegacy(worldNameIndex);
        if (!string.IsNullOrEmpty(world) && world != "None")
            vars.currentWorld = world;
    }
}

isLoading
{
    return current.GSync;
}

start
{
    if (current.startStatus == 0 && old.startStatus == 1  && current.menuStatus == 0 && current.GSync == false && old.GSync == false && current.playerBase < 0)
    {
        vars.split = 0;
        return true;
    }
}

reset
{
    if (current.menuStatus == 2 || current.menuStatus == 4)
    {
        vars.split = 0;
        return true;
    }

    if (vars.uharaInitialized && vars.currentWorld == "Start_HS")
    {
        vars.split = 0;
        return true;
    }
}

split
{
    if (vars.uharaInitialized)
    {
        if (vars.oldWorld != vars.currentWorld)
        {
            if ((vars.currentWorld == "Set2Main" && vars.split == 0) ||
                (vars.currentWorld == "Set3Main" && vars.split == 1) ||
                (vars.currentWorld == "Set4Main" && vars.split == 2) ||
                (vars.currentWorld == "Set5Main" && vars.split == 3))
            {
                vars.split++;
                return true;
            }
        }
        
        if (vars.currentWorld == "Set5Main" && vars.split == 4 &&
            current.startStatus == 1 && old.startStatus == 0 &&
            current.YCoord > 9800 && current.ZCoord > 26800)
        {
            vars.split++;
            return true;
        }
    }
    return false;
}

exit
{
    timer.IsGameTimePaused = true;
}
