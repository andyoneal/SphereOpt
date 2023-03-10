using UnityEngine;

namespace SphereOpt;

public class CustomShaderDesc
{
    public readonly string shortName;
    public readonly Shader shader;
    public readonly string shaderName;

    public CustomShaderDesc (string shortName, string customShaderName)
    {
        shader = CustomShaderManager.GetShader(customShaderName);
        if (shader == null) SphereOpt.logger.LogError($"Could not find shader for name: {customShaderName}");
        shaderName = customShaderName;
        this.shortName = shortName;
    }
}