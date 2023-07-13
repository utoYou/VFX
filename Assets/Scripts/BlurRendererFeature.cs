using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BlurRendererFeature : ScriptableRendererFeature
{
    [Serializable]
    public class BlurSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material blurMaterial = null;

        [Range(2, 15)]
        public int blurPasses = 1;

        [Range(1, 4)]
        public int downsample = 1;
        public bool copyToFramebuffer;
        public string targetName = "_blurTexture";
    }

    public BlurSettings settings = new BlurSettings();
    private BlurRenderPass _scriptablePass;

    public override void Create()
    {
        _scriptablePass = new BlurRenderPass("BlurRenderPass");
        _scriptablePass._blurMaterial = settings.blurMaterial;
        _scriptablePass._passes = settings.blurPasses;
        _scriptablePass._downsample = settings.downsample;
        _scriptablePass._copyToFramebuffer = settings.copyToFramebuffer;
        _scriptablePass._targetName = settings.targetName;

        _scriptablePass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        _scriptablePass.Setup(src);
        renderer.EnqueuePass(_scriptablePass);
    }
}
