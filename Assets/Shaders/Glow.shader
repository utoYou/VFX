Shader "Custom/Glow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _GlowTex ("Glow Texture", 2D) = "white" {}
        _GlowColor ("Glow Color", Color) = (1, 1, 1, 1)
        _Glow("Glow Color Intensity", Range(0, 100)) = 10
        _GlowGlobal ("Global Glow Intensity", Range(1, 100)) = 1
        _EditorDrawers("Editor Drawers", Int) = 6
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
            #pragma shader_feature GLOWTEX_ON
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
            sampler2D _GlowTex;
            half4 _GlowColor;
            half _Glow, _GlowGlobal;

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
                half4 col = tex2D(_MainTex, i.uv);
                half4 emission;
                #if GLOWTEX_ON
                emission = tex2D(_GlowTex, i.uv);
                #else
                emission = col;
                #endif
                col.rgb *= _GlowGlobal;
                emission.rgb *= emission.a * col.a * _Glow * _GlowColor;
                col.rgb += emission.rgb;
                return col;
            }
            ENDHLSL
        }
    }
    CustomEditor "GlowShaderMaterialInspector"
}