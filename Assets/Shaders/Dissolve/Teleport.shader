Shader "Custom/Teleport"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DissolveTex ("Dissolve Texture", 2D) = "white" {}
        _Progress ("Progress", Range(0, 1)) = 0
        _NoiseDensity ("Noise Density", Range(0, 60)) = 0
        _BeamSize ("Beam Size", Range(0.01, 0.15)) = 0.01
        [HDR]
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Cull Off
            Lighting Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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

            sampler2D _MainTex;
            sampler2D _DissolveTex;
            half _Progress;
            half _NoiseDensity;
            half _BeamSize;
            half4 _Color;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DissolveTex_ST;
            CBUFFER_END

            float2 random(float2 uv)
            {
                uv = float2(dot(uv, float2(127.1, 311.7)),
                            dot(uv, float2(269.5, 183.3)));
                return float2(-1.0 + 2.0 * frac(sin(uv) * 43758.5453123));
            }

            float noise(float2 uv)
            {
                float2 uv_index = floor(uv);
                float2 uv_frac = frac(uv);

                float2 blur = smoothstep(0.0, 1.0, uv_frac);

                return lerp(lerp(dot(random(uv_index + float2(0, 0)), uv_frac - float2(0, 0)),
                                dot(random(uv_index + float2(1, 0)), uv_frac - float2(1, 0)), blur.x),
                            lerp(dot(random(uv_index + float2(0, 1)), uv_frac - float2(0, 1)),
                                dot(random(uv_index + float2(1, 1)), uv_frac - float2(1, 1)), blur.x), blur.y) * 0.5 + 0.5;
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 mainColor = tex2D(_MainTex, i.uv);
                float noiseValue = noise(i.uv * _NoiseDensity) * (1 -i.uv.y);

                float d1 = step(_Progress, noiseValue);
                float d2 = step(_Progress - _BeamSize, noiseValue);

                half3 beam = (d2 - d1) * _Color.rgb;
                mainColor.rgb += beam;
                mainColor.a *= d2;
                return mainColor;
            }
            ENDHLSL
        }
    }
}