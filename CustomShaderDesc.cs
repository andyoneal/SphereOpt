using UnityEngine;

namespace SphereOpt;

public class CustomShaderDesc
{
    public readonly string shortName;
    public readonly Shader shader;
    public readonly string shaderName;
    public readonly string replacementForShader;

    public CustomShaderDesc (string shortName, string shaderToReplace, string replacementShader)
    {
        shader = CustomShaderManager.GetShader(replacementShader);
        if (shader == null) SphereOpt.logger.LogError($"Could not find shader for name: {replacementShader}");
        shaderName = replacementShader;
        replacementForShader = shaderToReplace;
        this.shortName = shortName;
    }
}