Shader "Custom/SimpleBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Offset ("Offset", float) = 0.5
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

            Lighting Off
            ZWrite Off

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

            sampler2D _MainTex;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            half _Offset;
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
                half2 res = _MainTex_TexelSize.xy;
                half p = _Offset;

                half4 col;
                col.rgb = tex2D(_MainTex, i.uv).rgb;
                col.rgb += tex2D(_MainTex, i.uv + float2(p, p) * res).rgb;
                col.rgb += tex2D(_MainTex, i.uv + float2(p, -p) * res).rgb;
                col.rgb += tex2D(_MainTex, i.uv + float2(-p, p) * res).rgb;
                col.rgb += tex2D(_MainTex, i.uv + float2(-p, -p) * res).rgb;
                col.rgb /= 5.0f;
                col.a = 1.0;

                return col;
            }
            ENDHLSL
        }
    }
}