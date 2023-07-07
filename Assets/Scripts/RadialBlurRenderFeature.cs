using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

[Serializable]
public class RadialBlurRenderFeature : ScriptableRendererFeature
{
    [SerializeField] private PostprocessTiming _timing = PostprocessTiming.AfterPostprocess;
    [SerializeField] private bool _applyToSceneView = true;

    private RadialBlurRenderPass _postProcessPass;
    private Shader _shader;

    public override void Create()
    {
        _shader = Shader.Find("Hidden/Radial Blur");
        _postProcessPass = new RadialBlurRenderPass(_applyToSceneView, _shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _postProcessPass.Setup(renderer.cameraColorTarget, _timing);
        renderer.EnqueuePass(_postProcessPass);
    }
}