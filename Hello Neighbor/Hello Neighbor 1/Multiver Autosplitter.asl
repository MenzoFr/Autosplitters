// this could probably highly be optimized especially for the init and update section but i'm not sure how to do it so sorry for your eyes
// huge thanks to uhara (rumii) for the GWorld names stuff
state("HelloNeighbor-Win64-Shipping", "v0.8")
{
    int menuStatus: 0x0383C0D0, 0x920, 0x550;
    int startStatus: 0x0383C0D0, 0xD0C; 
    bool IsLoading: 0x3A361A0;
}
state("HelloNeighbor-Win64-Shipping", "v1.1.6")
{
    int menuStatus: 0x02C1B640, 0x900, 0x7D8;
    byte startStatus: 0x02C1B640, 0xCFC; 
    bool IsLoading: 0x029C2C44;
}
state("HelloNeighbor-Win64-Shipping", "v1.4")
{
    int menuStatus: 0x02F9C2C0, 0x880, 0x7C8;
    byte startStatus: 0x02F9C2C0, 0x360, 0x3F8;
    bool IsLoading: 0x2D59A44;
}
state("HelloNeighbour-Win64-Shipping", "Pre Alpha")
{
    byte playerBase: 0x01FE0088, 0x118, 0x58, 0x0;
    float XCoord: 0x01FE0088, 0x118, 0x58, 0x158, 0x104;
    float doorAngle: 0x020834A8, 0x10A0, 0x7B8, 0xB8, 0x158;
    float endAngle: 0x01FE0088, 0x30, 0xA0, 0x750, 0x3F0, 0x158;
    float neighborX: 0x020272B0, 0x118, 0x68, 0x158, 0x104;
}
state("HelloNeighborReborn-Win64-Shipping", "Alpha 1")
{
    float XCoord: 0x0238D478, 0x118, 0x130, 0x160, 0x124;
    float YCoord: 0x0238D478, 0x118, 0x130, 0x160, 0x128;
    float ZCoord: 0x0238D478, 0x118, 0x130, 0x160, 0x120;
    float introTime: 0x0238D478, 0x118, 0x80, 0x3AC;
    float FOV: 0x02399C40, 0x30, 0x3D8, 0x364;
}
state("HelloNeighborReborn", "Alpha 2") 
{
    float XCoord: 0x05A1DB40, 0x3F8, 0x134;
    float YCoord: 0x05A1DB40, 0x3F8, 0x138;
    float ZCoord: 0x05A1DB40, 0x3F8, 0x130; 
    int consoleCommand: 0x05AE11D0, 0x10, 0xB0;
    int endState: 0x59D4F50;
    int startStatus: 0x05A1DB40, 0x3E8, 0x530;
    int currentWorld: 0x05B22AF0, 0x18;
}
state("HelloNeighborReborn-Win64-Shipping", "Alpha 3")
{
    float XCoord: 0x02650AC0, 0x3F0, 0x144;
    float YCoord: 0x02650AC0, 0x3F0, 0x148;
    float ZCoord: 0x02650AC0, 0x3F0, 0x140;
}
state("HelloNeighborReborn-Win64-Shipping", "Alpha 4")
{
    float XCoord: 0x02D077D0, 0x168, 0x1A4;
    float YCoord: 0x02D077D0, 0x168, 0x1A8;
    float ZCoord: 0x02D077D0, 0x168, 0x1A0;
    int menuStatus: 0x02E92CC0, 0xB10, 0x20, 0x20, 0x20, 0x3C8;
    int IsLoading: 0x02E924E0, 0xC44;
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "In order to remove the loads, you need to switch to Game Time as a timing method.\nWould you like to switch?",
            "LiveSplit | Hello Neighbor",
            MessageBoxButtons.YesNo);
        if (mbox == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }

    settings.Add("recommendedSplits", true, "Recommended Splits");
    settings.Add("useRecommendedSplits", false, "Use recommended splits (Full Game)", "recommendedSplits");
    settings.Add("useRecommendedSplitsAlpha", false, "Use recommended splits (Pre Alpha, Alpha 1, 2 and 3)", "recommendedSplits");
    settings.Add("useRecommendedSplitsAlpha4", false, "Use recommended splits (Alpha 4)", "recommendedSplits");
    vars.lastSplitsSetting = false;
    vars.lastSplitsSettingAlpha = false;
    vars.lastSplitsSettingAlpha4 = false;
    vars.lastXCoordAddress = IntPtr.Zero;
    vars.uharaInitialized = false;
}


init
{
    vars.currentWorld = "";
    vars.oldWorld = "";
    vars.split = 0;
    vars.vsplit = 0;
    vars.lastVersion = "";
    vars.hasStarted = false;

    if (modules.First().ModuleMemorySize == 51978240)
        version = "v1.1.6";
    else if (modules.First().ModuleMemorySize == 64610304)
        version = "v0.8";
    else if (modules.First().ModuleMemorySize == 55689216)
        version = "v1.4";
    else if (modules.First().ModuleMemorySize == 36474880)
        version = "Pre Alpha";
    else if (modules.First().ModuleMemorySize == 40443904)
        version = "Alpha 1";
    else if (modules.First().ModuleMemorySize == 45256704)
        version = "Alpha 3";
    else if (modules.First().ModuleMemorySize == 102002688)
        version = "Alpha 2";
    else if (modules.First().ModuleMemorySize == 52490240)
        version = "Alpha 4";
    else
        version = "";
    
    if (version == "v1.1.6" || version == "v0.8" || version == "v1.4" || version == "Alpha 4")
    {
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
    else if (modules.First().ModuleMemorySize == 36474880)
        version = "Pre Alpha";
    else if (modules.First().ModuleMemorySize == 40443904)
        version = "Alpha 1";
    else if (modules.First().ModuleMemorySize == 45256704)
        version = "Alpha 3";
    else if (modules.First().ModuleMemorySize == 102002688)
        version = "Alpha 2";
    else if (modules.First().ModuleMemorySize == 52490240)
        version = "Alpha 4";
    else
        version = "";

    if (settings["useRecommendedSplits"] != vars.lastSplitsSetting && 
        (version == "v1.1.6" || version == "v0.8" || version == "v1.4"))
    {
        if (settings["useRecommendedSplits"])
        {
            timer.Run.Clear();
            timer.Run.CategoryName = "Any%";
            timer.Run.Add(new LiveSplit.Model.Segment("Act 1"));
            timer.Run.Add(new LiveSplit.Model.Segment("Act 1 Basement"));
            timer.Run.Add(new LiveSplit.Model.Segment("Act 2"));
            timer.Run.Add(new LiveSplit.Model.Segment("Act 3"));
            timer.Run.Add(new LiveSplit.Model.Segment("Act 3 Basement"));
            timer.Run.Add(new LiveSplit.Model.Segment("Act Final"));
            timer.Run.Add(new LiveSplit.Model.Segment("Shadow Boss"));
        }
        vars.lastSplitsSetting = settings["useRecommendedSplits"];
    }

    if (settings["useRecommendedSplitsAlpha"] != vars.lastSplitsSettingAlpha && 
        (version == "Pre Alpha" || version == "Alpha 1" || version == "Alpha 2" || version == "Alpha 3"))
    {
        if (settings["useRecommendedSplitsAlpha"])
        {
            timer.Run.Clear();
            if (version == "Pre Alpha")
                timer.Run.CategoryName = "Pre-Alpha";
            else
                timer.Run.CategoryName = version;
            timer.Run.Add(new LiveSplit.Model.Segment(version));
        }
        vars.lastSplitsSettingAlpha = settings["useRecommendedSplitsAlpha"];
    }

    if (settings["useRecommendedSplitsAlpha4"] != vars.lastSplitsSettingAlpha4 && version == "Alpha 4")
    {
        if (settings["useRecommendedSplitsAlpha4"])
        {
            timer.Run.Clear();
            timer.Run.CategoryName = "Alpha 4";
            timer.Run.Add(new LiveSplit.Model.Segment("Main Part"));
            timer.Run.Add(new LiveSplit.Model.Segment("Fear Darkness"));
            timer.Run.Add(new LiveSplit.Model.Segment("Basement"));
        }
        vars.lastSplitsSettingAlpha4 = settings["useRecommendedSplitsAlpha4"];
    }

    if (version == "v1.1.6" || version == "v0.8" || version == "v1.4" || version == "Alpha 4")
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
            vars.hasStarted = false;
            vars.lastVersion = version;
        }
        
        vars.oldWorld = vars.currentWorld;

        var worldNameIndex = vars.Resolver["GWorldName"].Current;
        var world = vars.Utils.FNameToStringLegacy(worldNameIndex);
        if (!string.IsNullOrEmpty(world) && world != "None")
            vars.currentWorld = world;
    }
    else
    {
        if (vars.lastVersion != version)
        {
            vars.split = 0;
            vars.vsplit = 0;
            vars.currentWorld = "";
            vars.oldWorld = "";
            vars.hasStarted = false;
            vars.lastVersion = version;
        }
    }
}

start
{
    if (version == "Pre Alpha")
    {
        return current.doorAngle > 0;
    }
    else if (version == "Alpha 1")
    {
        return current.FOV == 112 && old.FOV == 0 && current.introTime > 22;
    }
    else if (version == "Alpha 3")
    {
        if (
            (current.XCoord < 1224 || current.XCoord > 1225) ||
            (current.ZCoord < -7886 || current.ZCoord > -7885)
        ) {
            vars.hasStarted = true;
            return true;
        }
    }
    else if (version == "Alpha 2")
    {
        bool noIntro =
            current.consoleCommand != 2988 &&
            current.currentWorld != 36649 &&
            (old.XCoord >= 1421 && old.XCoord <= 1422 &&
             old.ZCoord >= 1323 && old.ZCoord <= 1324) &&
            (current.XCoord < 1421 || current.XCoord > 1422 ||
             current.ZCoord < 1323 || current.ZCoord > 1324);
        
        bool noIntroAlt =
            current.consoleCommand != 2988 &&
            current.currentWorld != 36649 &&
            (current.YCoord >= 96 && current.YCoord <= 97);
        
        bool Intro =
            current.consoleCommand != 2988 &&
            old.startStatus == 1 &&
            current.startStatus == 0 &&
            current.currentWorld == 36649 &&
            (current.XCoord >= 957 && current.XCoord <= 958) &&
            (current.YCoord >= 99 && current.YCoord <= 100) &&
            (current.ZCoord >= 1366 && current.ZCoord <= 1367);
        
        if (noIntro || noIntroAlt || Intro)
            return true;
    }
    else if (version == "Alpha 4")
    {
        return current.YCoord > 210 && current.YCoord < 250
            && current.XCoord > 1200 && current.XCoord < 1300
            && current.ZCoord > -7600 && current.ZCoord < -7500;
    }
    else if (version == "v1.1.6" || version == "v0.8" || version == "v1.4")
    {
        if (current.startStatus == vars.StartStatusValue && old.startStatus != vars.StartStatusValue &&
            current.menuStatus != vars.NewGameStatus && current.IsLoading == vars.StartIsLoadingCheck)
        {
            vars.split = 0;
            if (version == "v0.8")
                vars.vsplit = 0;

            return true;
        }
    }

    return false;
}

onStart
{
    if (version == "Alpha 1")
    {
        timer.SetGameTime(TimeSpan.FromSeconds(22.050));
    }
    else if (version == "Alpha 4")
    {
        timer.SetGameTime(TimeSpan.FromSeconds(49.783));
    }
}

reset
{
    if (string.IsNullOrEmpty(version))
        return true;

    if (version == "Pre Alpha")
    {
        return current.doorAngle == 0 && current.neighborX == -183 && current.XCoord > 5500;
    }
    else if (version == "Alpha 1")
    {
        return current.introTime < 1;
    }
    else if (version == "Alpha 3")
    {
        if (!vars.hasStarted)
            return false;

        if (
            current.XCoord >= 1224 && current.XCoord <= 1225 &&
            current.YCoord >= 210  && current.YCoord <= 211 &&
            current.ZCoord >= -7886 && current.ZCoord <= -7885
        ) {
            IntPtr baseAddress = modules.First().BaseAddress;
            IntPtr currentXCoordAddress = IntPtr.Zero;
            
            try
            {
                IntPtr ptr1 = memory.ReadPointer(baseAddress + 0x02650AC0);
                IntPtr ptr2 = memory.ReadPointer(ptr1 + 0x3F0);
                currentXCoordAddress = ptr2 + 0x144;
            }
            catch
            {
                return false;
            }
            
            if (vars.lastXCoordAddress == IntPtr.Zero || 
                vars.lastXCoordAddress != currentXCoordAddress)
            {
                vars.lastXCoordAddress = currentXCoordAddress;
                vars.hasStarted = false;
                return true;
            }
            
            return false;
        }

        return false;
    }
    else if (version == "Alpha 2")
    {
        if (current.consoleCommand == 2988)
            return true;
        
        return false;
    }
    else if (version == "Alpha 4")
    {
        return current.menuStatus == 1;
    }

    if (vars.currentWorld == "Start")
        return true;

    if (version == "v1.1.6" || version == "v0.8" || version == "v1.4")
    {
        if (current.menuStatus == vars.NewGameStatus && old.menuStatus != vars.NewGameStatus)
            return true;
    }

    return false;
}

split
{
    if (version == "Pre Alpha")
    {
        return old.endAngle < -179.9 && current.endAngle > -179.9 && current.playerBase == 16;
    }
    else if (version == "Alpha 1")
    {
        return current.FOV == 0 
            && current.XCoord > 800 && current.XCoord < 1300
            && current.YCoord > 200 && current.YCoord < 400
            && current.ZCoord > 500 && current.ZCoord < 1200;
    }
    else if (version == "Alpha 3")
    {
        if (current.YCoord < -2000 && current.ZCoord < 4400)
            return true;
        return false;
    }
    else if (version == "Alpha 2")
    {
        if (current.endState == old.endState + 1 && current.startStatus == 1 && current.YCoord < -9000) 
            return true;
    }
    else if (version == "Alpha 4")
    {
        if (vars.oldWorld != vars.currentWorld)
        {
            if ((vars.currentWorld == "Fear_Darkness" && vars.split == 0) ||
                (vars.currentWorld == "Alpha_4_Basement" && vars.split == 1) ||
                (vars.currentWorld == "Apartments" && vars.split == 2))
            {
                vars.split++;
                return true;
            }
        }
        return false;
    }

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
    if (version == "Pre Alpha" || version == "Alpha 1" || version == "Alpha 3" || version == "Alpha 2" || string.IsNullOrEmpty(version))
        return false;

    if (version == "v1.1.6" || version == "v1.4" || version == "v0.8")
    {
        return (version == "v1.1.6" || version == "v1.4") ? !current.IsLoading : current.IsLoading;
    }

    if (version == "Alpha 4")
    {
        return current.IsLoading != 0;
    }

    return false;
}
