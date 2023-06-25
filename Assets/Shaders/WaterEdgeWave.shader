Shader "Custom/WaterEdgeWave"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Base(RGB)", 2D) = "white" {}
        _SpeedX ("Speed X", float) = 1
        _SpeedY ("Speed Y", float) = 1
        _WaveScale ("Wave Scale", float) = 0.1
        _WavePhase ("Wave Phase", float) = 80
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
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                half3 normal : NROMAL;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            half4 _Color;
            sampler2D _MainTex;
            half _SpeedX;
            half _SpeedY;
            float _WaveScale;
            float _WavePhase;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                float phase = dot(v.vertex, float4(1, 1, 1, 1));
                float offset = sin(_WavePhase * (_Time.r + phase)) * _WaveScale;
                o.vertex = TransformObjectToHClip(v.vertex.xyz + float4(0, offset, 0, 0));
                o.uv = TRANSFORM_TEX(v.uv + frac(float2(_SpeedX, _SpeedY) * _Time.r), _MainTex);
                o.normal = v.normal;
                o.color = v.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 c = tex2D(_MainTex, i.uv) * _Color;
                c.a = c.a * i.color.a;
                return c;
            }
            ENDHLSL
        }
    }
}