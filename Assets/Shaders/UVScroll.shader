Shader "Custom/UVScroll"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScrollSpeedX ("Scroll Speed X", Range(-1, 1)) = 1
        _ScrollSpeedY ("Scroll Speed Y", Range(-1, 1)) = 1
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
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            // Cull Off
            Lighting Off
            // ZWrite Off
            // Blend SrcAlpha OneMinusSrcAlpha

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
            half _ScrollSpeedX;
            half _ScrollSpeedY;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float x = i.uv.x + (_ScrollSpeedX * _Time.y);
                float y = i.uv.y + (_ScrollSpeedY * _Time.y);
                return tex2D(_MainTex, float2(x, y));
            }
            ENDHLSL
        }
    }
}