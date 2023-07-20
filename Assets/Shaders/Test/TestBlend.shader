Shader "Custom/TestBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend ("Source Factor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend ("Destination Factor", Float) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "LightMode"="ForwardBase"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Lighting Off
            Blend [_SrcBlend] [_DstBlend]

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
                half4 color : COLOR;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                // フォグの計算で使うfog factor用のinterpolator
                float fogFactor: TEXCOORD1;
                float4 positionHCS : SV_POSITION;
                half4 color : COLOR;
            };

            sampler2D _MainTex;
            half4 _Color;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.positionHCS.z);
                o.color = v.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}