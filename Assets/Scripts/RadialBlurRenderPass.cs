using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public enum PostprocessTiming
{
    BeforePostprocess,
    AfterPostprocess
}

public class RadialBlurRenderPass : ScriptableRenderPass
{
    private const string RenderPassName = nameof(RadialBlurRenderPass);
    private const string ProfilingSamplerName = "SrcToDest";

    private readonly bool _applyToSceneView;
    private readonly int _mainTexPropertyId = Shader.PropertyToID("_MainTex");
    private readonly Material _material;
    private readonly ProfilingSampler _profilingSampler;
    private readonly int _sampleCountPropertyId = Shader.PropertyToID("_SampleCount");
    private readonly int _strengthPropertyId = Shader.PropertyToID("_Strength");

    private RenderTargetHandle _afterPostProcessTexture;
    private RenderTargetIdentifier _cameraColorTarget;
    private RenderTargetHandle _tempRenderTargetHandle;
    private RadialBlurVolume _volume;

    public RadialBlurRenderPass(bool applyToSceneView, Shader shader)
    {
        if (shader == null)
        {
            return;
        }

        _applyToSceneView = applyToSceneView;
        _profilingSampler = new ProfilingSampler(ProfilingSamplerName);
        _tempRenderTargetHandle.Init("_TempRT");
        _material = CoreUtils.CreateEngineMaterial(shader);
        _afterPostProcessTexture.Init("_AfterPostProcessTexture");
    }

    public void Setup(RenderTargetIdentifier cameraColorTarget, PostprocessTiming timing)
    {
        _cameraColorTarget = cameraColorTarget;
        renderPassEvent = GetRenderPassEvent(timing);
        var volumeStack = VolumeManager.instance.stack;
        _volume = volumeStack.GetComponent<RadialBlurVolume>();
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (_material == null)
        {
            return;
        }

        if (!renderingData.cameraData.postProcessEnabled)
        {
            return;
        }

        if (!_applyToSceneView && renderingData.cameraData.cameraType == CameraType.SceneView)
        {
            return;
        }

        if (!_volume.IsActive())
        {
            return;
        }
        
        var source = renderPassEvent == RenderPassEvent.AfterRendering && renderingData.cameraData.resolveFinalTarget
            ? _afterPostProcessTexture.Identifier()
            : _cameraColorTarget;

        var cmd = CommandBufferPool.Get(RenderPassName);
        cmd.Clear();
        var tempTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        tempTargetDescriptor.depthBufferBits = 0;
        cmd.GetTemporaryRT(_tempRenderTargetHandle.id, tempTargetDescriptor);

        using (new ProfilingScope(cmd, _profilingSampler))
        {
            _material.SetInt(_sampleCountPropertyId, _volume.sampleCount.value);
            _material.SetFloat(_strengthPropertyId, _volume.strength.value);
            cmd.SetGlobalTexture(_mainTexPropertyId, source);
            Blit(cmd, source, _tempRenderTargetHandle.Identifier(), _material);
        }

        Blit(cmd, _tempRenderTargetHandle.Identifier(), source);

        cmd.ReleaseTemporaryRT(_tempRenderTargetHandle.id);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    private static RenderPassEvent GetRenderPassEvent(PostprocessTiming postprocessTiming)
    {
        switch (postprocessTiming)
        {
            case PostprocessTiming.BeforePostprocess:
                return RenderPassEvent.BeforeRenderingPostProcessing;
            case PostprocessTiming.AfterPostprocess:
                return RenderPassEvent.AfterRendering;
            default:
                throw new ArgumentOutOfRangeException(nameof(postprocessTiming), postprocessTiming, null);
        }
    }
}