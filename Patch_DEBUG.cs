using HarmonyLib;

namespace SphereOpt
{
    public class Patch_DEBUG
    {
        [HarmonyPatch(typeof(StarSimulator), "UpdateUniversalPosition")]
        [HarmonyPostfix]
        private static void DEBUG_DisableFlare(StarSimulator __instance)
        {
            __instance.sunFlare.enabled = false;
        }
        
        [HarmonyPatch(typeof(PostEffectController), "Update")]
        [HarmonyPostfix]
        private static void DEBUG_DisableSunShafts(PostEffectController __instance)
        {
            __instance.sunShaft.enabled = false;
        }
    }
}