Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _WaterSpeed ("Water Speed", float) = 1
        _Water ("Water", 2D) = "white" {}
        _WaterOpaque ("Water Opaque", float) = 0.5
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
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
            };

            half4 _Color;
            half _WaterSpeed;
            sampler2D _Water;
            half _WaterOpaque;

            CBUFFER_START(UnityPerMaterial)
            float4 _Water_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                float speed = frac(_Time.r * _WaterSpeed);
                o.uv0 = TRANSFORM_TEX(v.uv + float2(speed, 0), _Water);
                o.uv1 = TRANSFORM_TEX(v.uv + float2(0, speed) + float2(0.12345, 0.1234), _Water);
                o.color = v.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half3 caustic0 = tex2D(_Water, i.uv0);
                half3 caustic1 = tex2D(_Water, i.uv1);
                half caustic = caustic0.r * caustic1.r;

                half node_1524 = i.color.a * caustic;
                half alpha = saturate(node_1524 + caustic);
                half3 emissive = lerp(_Color + half3(alpha, alpha, alpha), half3(1, 1, 1), alpha);
                return half4(emissive, max(i.color.r, _WaterOpaque));
            }
            ENDHLSL
        }
    }
}