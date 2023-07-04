Shader "Custom/Dissolve"
{
    Properties
    {
        [HDR]
        _BaseColor ("Color", Color) = (1, 1, 1)
        [HDR]
        _EdgeColor ("Dissolve Color", Color) = (0, 0, 0)
        _MainTex ("Texture", 2D) = "white" {}
        _DissolveTex ("Dissolve Texture", 2D) = "white" {}
        _AlphaClipThreshold ("Alpha Clip Threshold", Range(0, 1)) = 1
        _EdgeWidth ("Dissolve Margin Width", Range(0, 1)) = 0.01
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

            half4 _BaseColor;
            half4 _EdgeColor;
            sampler2D _MainTex;
            sampler2D _DissolveTex;
            half _AlphaClipThreshold;
            half _EdgeWidth;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DissolveTex_ST;
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
                half4 edgeColor = half4(1, 1, 1, 1);

                half4 dissolve = tex2D(_DissolveTex, i.uv);
                float alpha = (dissolve.r * 0.2 + dissolve.g * 0.7 + dissolve.b * 0.1) * 0.999 * (1 - i.uv.y);
                
                if (alpha < _AlphaClipThreshold + _EdgeWidth && _AlphaClipThreshold > 0)
                {
                    edgeColor = _EdgeColor;
                }
                if (alpha < _AlphaClipThreshold)
                {
                    discard;
                }
                return tex2D(_MainTex, i.uv) * _BaseColor * edgeColor;
            }
            ENDHLSL
        }
    }
}