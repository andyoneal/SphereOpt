using HarmonyLib;

namespace SphereOpt;

public static class Patch_DEBUG
{   
    [HarmonyPatch(typeof(DSPGame), "StartDemoGame")]
    [HarmonyPrefix]
    private static bool DSPGame_StartDemoGame(ref int index)
    {
        if(SphereOpt.configDEBUGSameTitleScreen) index = -2;
        return true;
    }
    
    [HarmonyPatch(typeof(PostEffectController), "Update")]
    [HarmonyPostfix]
    private static void PostEffectController_Update(PostEffectController __instance)
    {
        if(SphereOpt.configDEBUGDisableSunShafts) sunShaft.enabled = false;
    }
    
    
}