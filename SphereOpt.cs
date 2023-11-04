using System.Collections.Generic;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using System.IO;
using System.Reflection;
using UnityEngine;
using BepInEx.Configuration;

namespace SphereOpt;

[BepInPlugin(PluginInfo.PLUGIN_GUID, PluginInfo.PLUGIN_NAME, PluginInfo.PLUGIN_VERSION)]
public class SphereOpt : BaseUnityPlugin
{
    public static ManualLogSource logger;
    private static AssetBundle bundle;
    private static readonly string AssemblyPath = Path.GetDirectoryName(Assembly.GetAssembly(typeof(SphereOpt)).Location);

    private static Dictionary<int, InstDysonShellRenderer> instRenderers = new();
    
    private ConfigEntry<bool> configDEBUGSameTitleScreen;
    private ConfigEntry<bool> configDEBUGDisableSunShafts;

    private static AssetBundle Bundle
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
        logger = Logger;
        
        configDEBUGSameTitleScreen = Config.Bind("Debug", 
            "AlwaysSameTitleScreen",
            false,
            "Show the same title screen on every launch instead of a random one.");
            
        configDEBUGDisableSunShafts = Config.Bind("Debug", 
            "DisableSunShafts",
            false,
            "Disable the sun shafts image effect.");

        CustomShaderManager.InitWithBundle(Bundle);

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell-inst",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit Instanced"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonframe",
            "VF Shaders/Dyson Sphere/Frame Inst REPLACE",
            "VF Shaders/Dyson Sphere/Frame Inst"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonnode",
            "VF Shaders/Dyson Sphere/Node Inst REPLACE",
            "VF Shaders/Dyson Sphere/Node Inst"
        );
        

        Harmony.CreateAndPatchAll(typeof(Patch_VFPreload));
        Harmony.CreateAndPatchAll(typeof(Patch_DysonShell));
        Harmony.CreateAndPatchAll(typeof(Patch_DysonSphereSegmentRenderer));
        Harmony.CreateAndPatchAll(typeof(Patch_DEBUG));
    }

    public static InstDysonShellRenderer getInstDysonShellRendererForSphere(DysonSphere ds)
    {
        if (!instRenderers.ContainsKey(ds.starData.id))
        {
            instRenderers[ds.starData.id] = new InstDysonShellRenderer(ds);
        }
        return instRenderers[ds.starData.id];
    }

    public static void RemoveRenderer(DysonSphere ds)
    {
        //instRenderers[ds.starData.id] = null;
        instRenderers.Remove(ds.starData.id);
    }
}