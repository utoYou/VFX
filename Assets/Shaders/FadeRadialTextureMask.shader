Shader "Custom/FadeRadialTextureMask"
{
    Properties
    {
        [NoScaleOffset]
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _Scale ("Scale", Range(0, 3)) = 0
        _CenterX ("Center X", Range(0, 1)) = 0.5
        _CenterY ("Center Y", Range(0, 1)) = 0.5
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
                float2 uv2 : TEXCOORD1;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 positionHCS : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            half4 _MainTex_TexelSize;
            half _Scale;
            half _CenterX;
            half _CenterY;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MaskTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv2 = TRANSFORM_TEX(v.uv2, _MaskTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half2 resolution = half2((_MainTex_TexelSize.x / _MainTex_TexelSize.y).xx);
                half2 center = half2(_CenterX, _CenterY);
                half2 maskUV = i.uv2 - center;
                maskUV = maskUV * pow(_Scale, 3);
                maskUV = maskUV + center;
                half4 maskCol = tex2D(_MaskTex, maskUV);

                // maskCol.aによって_MainTexを表示するかどうかを決定する。
                // TODO: _MaskTexの拡大率が大きい場合にジャギるのを解消したい
                // TODO: _MaskTexは最終的に縮小して完全に見えないようにしたい、現状は小さくなったのが残ってる
                half4 mainCol = tex2D(_MainTex, i.uv);
                half showMainCol = smoothstep(0, 0.01, maskCol.a);
                half4 col = lerp(half4(0, 0, 0, 1), mainCol, showMainCol);
                return col;
            }
            ENDHLSL
        }
    }
}