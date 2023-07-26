Shader "Custom/TestLerp"
{
    Properties
    {
        _Skin01 ("Skin 01", 2D) = "white" {}
        _Skin02 ("Skin 02", 2D) = "white" {}
        _Lerp ("Lerp", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "LightMode"="ForwardBase"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

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
                float2 uv2 : TEXCOORD1;
                half4 color : COLOR;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                // フォグの計算で使うfog factor用のinterpolator
                float fogFactor: TEXCOORD2;
                float4 positionHCS : SV_POSITION;
                half4 color : COLOR;
            };

            sampler2D _Skin01;
            sampler2D _Skin02;
            half _Lerp;

            CBUFFER_START(UnityPerMaterial)
            float4 _Skin01_ST;
            float4 _Skin02_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _Skin01);
                o.uv2 = TRANSFORM_TEX(v.uv2, _Skin02);
                o.fogFactor = ComputeFogFactor(o.positionHCS.z);
                o.color = v.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 skin01 = tex2D(_Skin01, i.uv);
                half4 skin02 = tex2D(_Skin02, i.uv2);
                half4 render = lerp(skin01, skin02, _Lerp);
                return render;
            }
            ENDHLSL
        }
    }
}