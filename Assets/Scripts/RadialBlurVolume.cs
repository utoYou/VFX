using System;
using UnityEngine.Rendering;

[Serializable]
[VolumeComponentMenu("Radial Blur")]
public class RadialBlurVolume : VolumeComponent
{
    public bool IsActive() => strength.value != 0;
    public ClampedIntParameter sampleCount = new ClampedIntParameter(8, 4, 16);
    public FloatParameter strength = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);
}
