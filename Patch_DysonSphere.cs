using HarmonyLib;

namespace SphereOpt
{
    public static class Patch_DysonSphere
    {
        [HarmonyPatch(typeof(DysonSphere), "UpdateColor")]
        [HarmonyPostfix]
        private static void DysonSphere_UpdateColor(DysonSphere __instance, DysonNode node)
        {
            //TODO
        }

        [HarmonyPatch(typeof(DysonSphere), "UpdateColor")]
        [HarmonyPostfix]
        private static void DysonSphere_UpdateColor(DysonSphere __instance, DysonFrame frame)
        {
            //TODO
        }

        [HarmonyPatch(typeof(DysonSphere), "UpdateProgress")]
        [HarmonyPostfix]
        private static void DysonSphere_UpdateProgress(DysonSphere __instance, DysonNode node)
        {
            //TODO
        }

        [HarmonyPatch(typeof(DysonSphere), "UpdateProgress")]
        [HarmonyPostfix]
        private static void DysonSphere_UpdateProgress(DysonSphere __instance, DysonFrame frame)
        {
            //TODO
        }

        [HarmonyPatch(typeof(DysonSphere), "UpdateStates")]
        [HarmonyPostfix]
        private static void DysonSphere_UpdateStates(DysonSphere __instance, DysonNode node, uint state, bool add, bool remove)
        {
            //TODO
        }

        [HarmonyPatch(typeof(DysonSphere), "UpdateStates")]
        [HarmonyPostfix]
        private static void DysonSphere_UpdateStates(DysonSphere __instance, DysonFrame frame, uint state, bool add, bool remove)
        {
            //TODO
        }
    }
}