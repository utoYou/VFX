Shader "Custom/TestFloor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _Sections ("Sections", Range(2, 10)) = 5
        _Gamma ("Gamma", Range(0, 1)) = 1
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
            half _Sections;
            half _Gamma;

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
                float fv = floor(i.uv.y * _Sections) * (_Sections / 100.0);
                return half4(fv.xxx, 1) + _Gamma;
            }
            ENDHLSL
        }
    }
}