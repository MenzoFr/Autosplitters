state("HelloNeighbor-Win64-Shipping", "v1.1.6")
{
    int menuStatus: 0x02C1B640, 0x900, 0x7D8;
    byte startStatus: 0x02C1B640, 0xCFC; 
    bool IsLoading: 0x029C2C44;
}
state("HelloNeighbor-Win64-Shipping", "v0.8")
{
    int menuStatus: 0x0383C0D0, 0x920, 0x550;
    int startStatus: 0x0383C0D0, 0xD0C; 
    bool IsLoading: 0x3A361A0;
}
state("HelloNeighbor-Win64-Shipping", "v1.4")
{
    int menuStatus: 0x02F9C2C0, 0x880, 0x7C8;
    byte startStatus: 0x02F9C2C0, 0x360, 0x3F8;
    bool IsLoading: 0x2D59A44;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.EnableDebug();
    
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "In order to remove the loads, you need to switch to Game Time as a timing method.\nWould you like to switch?",
            "LiveSplit | Hello Neighbor",
            MessageBoxButtons.YesNo);
        if (mbox == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

init
{
    // huge thanks to uhara (rumii) for this it was genuinely helpful
    vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");
    vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
    
    vars.currentWorld = "";
    vars.oldWorld = "";
    vars.split = 0;
    vars.vsplit = 0;
    vars.lastVersion = "";

    if (modules.First().ModuleMemorySize == 51978240)
        version = "v1.1.6";
    else if (modules.First().ModuleMemorySize == 64610304)
        version = "v0.8";
    else if (modules.First().ModuleMemorySize == 55689216)
        version = "v1.4";
    else
        version = "";
    
    if (version == "v1.1.6")
    {
        vars.NewGameStatus = 3;
        vars.StartIsLoadingCheck = true;
    }
    else if (version == "v0.8")
    {
        vars.NewGameStatus = 2;
        vars.StartIsLoadingCheck = false;
    }
    else if (version == "v1.4")
    {
        vars.NewGameStatus = 4;
        vars.StartIsLoadingCheck = true;
    }

    vars.StartStatusValue = 0;
}

update
{
    if (modules.First().ModuleMemorySize == 51978240)
        version = "v1.1.6";
    else if (modules.First().ModuleMemorySize == 64610304)
        version = "v0.8";
    else if (modules.First().ModuleMemorySize == 55689216)
        version = "v1.4";
    else
        version = "";

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

    if (vars.lastVersion != version || !uharaOk || vars.Utils == null)
    {
        try
        {
            vars.Uhara = Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
            try { vars.Uhara.EnableDebug(); } catch {}
        }
        catch
        {
            vars.lastVersion = version;
            return;
        }
        try
        {
            vars.Utils = vars.Uhara.CreateTool("UnrealEngine", "Utils");

            try { vars.Resolver.Clear(); } catch {}
            vars.Resolver.Watch<uint>("GWorldName", vars.Utils.GWorld, 0x18);
        }
        catch
        {
            vars.lastVersion = version;
            return;
        }

        vars.split = 0;
        vars.vsplit = 0;
        vars.currentWorld = "";
        vars.oldWorld = "";
        vars.lastVersion = version;
    }
    vars.oldWorld = vars.currentWorld;

    var worldNameIndex = vars.Resolver["GWorldName"].Current;
    var world = vars.Utils.FNameToStringLegacy(worldNameIndex);
    if (!string.IsNullOrEmpty(world) && world != "None")
        vars.currentWorld = world;
}

start
{
    if (current.startStatus == vars.StartStatusValue && old.startStatus != vars.StartStatusValue &&
        current.menuStatus != vars.NewGameStatus && current.IsLoading == vars.StartIsLoadingCheck)
    {
        vars.split = 0;
        if (version == "v0.8")
            vars.vsplit = 0;

        return true;
    }

    return false;
}

reset
{
    if (vars.currentWorld == "Start")
        return true;

    if (current.menuStatus == vars.NewGameStatus && old.menuStatus != vars.NewGameStatus)
        return true;

    return false;
}

split
{
    if (vars.oldWorld != vars.currentWorld)
    {
        if ((vars.currentWorld == "Act1_Basement_Main" && vars.split == 0) ||
            (vars.currentWorld == "Act2_Main" && vars.split == 1) ||
            (vars.currentWorld == "Apartments" && vars.split == 2) ||
            (vars.currentWorld == "Act3_Basement" && vars.split == 3) ||
            (vars.currentWorld == "Final" && vars.split == 4) ||
            (vars.currentWorld == "Final_Thing" && vars.split == 5) ||
            (vars.currentWorld == "FinaleMain" && vars.split == 6))
        {
            vars.split++;
            return true;
        }
    }
    return false;
}

isLoading
{
    return (version == "v1.1.6" || version == "v1.4") ? !current.IsLoading : current.IsLoading;
}
