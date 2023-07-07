Shader "Hidden/Radial Blur"
{
    Properties
    {
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "IgnoreProjector"="True"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half _SampleCount;
            half _Strength;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 color = 0;
                half2 symmetryUv = i.uv - 0.5;
                half distance = length(symmetryUv);
                half factor = _Strength / _SampleCount * distance;
                for (int i = 0; i < _SampleCount; i++)
                {
                    half uvOffset = 1 - factor * i;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, symmetryUv * uvOffset + 0.5);
                }
                color /= _SampleCount;
                return color;
            }
            ENDHLSL
        }
    }
}