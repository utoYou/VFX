using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BlurRenderPass : ScriptableRenderPass
{
    public Material _blurMaterial;
    public int _passes;
    public int _downsample;
    public bool _copyToFramebuffer;
    public string _targetName;

    private string _profilerTag;
    private int _tempId1;
    private int _tempId2;

    private RenderTargetIdentifier _tempRT1;
    private RenderTargetIdentifier _tempRT2;

    private RenderTargetIdentifier _source { get; set; }

    public void Setup(RenderTargetIdentifier source)
    {
        _source = source;
    }

    public BlurRenderPass(string profilerTag)
    {
        _profilerTag = profilerTag;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        var width = cameraTextureDescriptor.width / _downsample;
        var height = cameraTextureDescriptor.height / _downsample;

        _tempId1 = Shader.PropertyToID("_TmpBlurRT1");
        _tempId2 = Shader.PropertyToID("_TmpBlurRT2");
        cmd.GetTemporaryRT(_tempId1, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
        cmd.GetTemporaryRT(_tempId2, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

        _tempRT1 = new RenderTargetIdentifier(_tempId1);
        _tempRT2 = new RenderTargetIdentifier(_tempId2);

        ConfigureTarget(_tempRT1);
        ConfigureTarget(_tempRT2);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(_profilerTag);

        RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
        opaqueDesc.depthBufferBits = 0;

        // first pass
        cmd.SetGlobalFloat("_Offset", 1.5f);
        cmd.Blit(_source, _tempRT1, _blurMaterial);

        for (var i = 1; i < _passes - 1; i++)
        {
            cmd.SetGlobalFloat("_Offset", 0.5f + i);
            cmd.Blit(_tempRT1, _tempRT2, _blurMaterial);

            // pingpong
            var rttemp = _tempRT1;
            _tempRT1 = _tempRT2;
            _tempRT2 = rttemp;
        }

        // final pass
        cmd.SetGlobalFloat("_Offset", 0.5f + _passes - 1f);
        if (_copyToFramebuffer)
        {
            cmd.Blit(_tempRT1, _source, _blurMaterial);
        }
        else
        {
            cmd.Blit(_tempRT1, _tempRT2, _blurMaterial);
            cmd.SetGlobalTexture(_targetName, _tempRT2);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        
    }
}
