using HarmonyLib;
using UnityEngine;

namespace SphereOpt
{
    internal static class Patch_VFPreload
    {
        [HarmonyPatch(typeof(VFPreload), "SaveMaterial")]
        [HarmonyPrefix]
        private static bool VFPreload_SaveMaterial(Material mat)
        {
            if (mat == null)
            {
                return false;
            }

            CustomShaderManager.ReplaceShaderIfAvailable(mat);

            return true;
        }

        [HarmonyPatch(typeof(VFPreload), "SaveMaterials", typeof(Material[]))]
        [HarmonyPrefix]
        private static bool VFPreload_SaveMaterials(Material[] mats)
        {
            if (mats == null)
            {
                return false;
            }

            foreach (Material mat in mats)
            {
                if (mat == null) continue;
                CustomShaderManager.ReplaceShaderIfAvailable(mat);
            }
            return true;
        }

        [HarmonyPatch(typeof(VFPreload), "SaveMaterials", typeof(Material[][]))]
        [HarmonyPrefix]
        private static bool VFPreload_SaveMaterials(Material[][] mats)
        {
            if (mats == null)
            {
                return false;
            }

            foreach (Material[] matarray in mats)
            {
                if(matarray == null) continue;
                foreach (var mat in matarray)
                {
                    if(mat == null) continue;
                    CustomShaderManager.ReplaceShaderIfAvailable(mat);
                }
            }
            return true;
        }
    }
}