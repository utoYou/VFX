// 実装的にアルファを含む画像では見た目を損なうかも
Shader "Custom/Ripple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Progress ("Progress", Range(0, 1.0)) = 0
        _CellCount ("CellCount", Range(2.0, 20.0)) = 10.0
        _Speed ("Speed", Range(0.1, 2.0)) = 1.0
        _Smoothness ("Smoothness", Range(0.5, 2.0)) = 1.0
        _Angle ("Angle", Range(0, 360)) = 45
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
            half4 _Color;
            half _Progress;
            half _CellCount;
            half _Speed;
            half _Smoothness;
            half _Angle;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float rectanglef (float2 uv, half width, half height, half feather)
            {
                float2 uvCartesian = uv * 2.0 - 1.0;
                float2 uvReflected = abs(uvCartesian);
                float dfx = smoothstep(width, width + feather, uvReflected.x);
                float dfy = smoothstep(height, height + feather, uvReflected.y);
                return max(dfx, dfy);
            }

            float2 rotation (float2 uv, float2 center, half ang)
            {
                float2x2 rotationMat = float2x2(
                  float2(cos(ang), -sin(ang)),
                  float2(sin(ang), cos(ang))
                );
                uv -= center;
                uv = mul(uv, rotationMat);
                uv += center;
                return uv;
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
                half2 igrid = floor(i.uv * _CellCount) / _CellCount;

                igrid = rotation(igrid, float2(0.5, 0), _Angle * 3.14159 / 180);
                igrid.x += 1 - (_Progress * _Speed * 3.0);
                half2 fgrid = frac(i.uv * _CellCount);
                half rectMask = rectanglef(igrid, 0.001, 2.0, _Smoothness);
                half gridMask = 1.0 - rectanglef(fgrid, rectMask, rectMask, 0);
                half outlineMask = 1.0 - rectanglef(fgrid, rectMask + 0.1, rectMask + 0.1, 0) - gridMask;
                half3 outline = outlineMask * _Color;
                half3 mainColor = tex2D(_MainTex, i.uv);
                return half4(lerp(mainColor, outline, outlineMask), outlineMask + gridMask);
            }
            ENDHLSL
        }
    }
}