using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using System.IO;
using System.Reflection;
using UnityEngine;

namespace SphereOpt;

[BepInPlugin(PluginInfo.PLUGIN_GUID, PluginInfo.PLUGIN_NAME, PluginInfo.PLUGIN_VERSION)]
public class SphereOpt : BaseUnityPlugin
{
    public static ManualLogSource logger;
    private static AssetBundle bundle;
    private static readonly string AssemblyPath = Path.GetDirectoryName(Assembly.GetAssembly(typeof(SphereOpt)).Location);

    public static AssetBundle Bundle
    {
        get
        {
            if (bundle == null)
            {
                var path = Path.Combine(AssemblyPath, "sphereopt-bundle");
                if (File.Exists(path))
                {
                    bundle = AssetBundle.LoadFromFile(path);
                }
                else
                {
                    logger.LogError("Failed to load AssetBundle!".Translate());
                    return null;
                }
            }
            return bundle;
        }
    }
    private void Awake()
    {
        // Plugin startup logic
        logger = Logger;
        logger.LogInfo($"Plugin {PluginInfo.PLUGIN_GUID} is loaded!");

        CustomShaderManager.InitWithBundle(Bundle);

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE"
        );

        Harmony.CreateAndPatchAll(typeof(Patch_VFPreload));
    }
}