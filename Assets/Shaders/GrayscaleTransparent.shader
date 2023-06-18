// Textureをグレースケール化させるShader
// _Ratioが1の場合グレースケール、0の場合は元のTexture表示
// ※UIに設定する場合はTransparent扱いする必要があるらしい、OpaqueだとSceneViewで表示されない

Shader "Custom/GrayscaleTransparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ratio("Ratio", Range(0, 1)) = 1
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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                // フォグの計算で使うfog factor用のinterpolator
                float fogFactor: TEXCOORD1;
                float4 vertex : SV_POSITION;
                half4 color : COLOR;
            };

            sampler2D _MainTex;
            float _Ratio;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                o.color = v.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 color = tex2D(_MainTex, i.uv);
                half luminosity = dot(color, half3(0.299, 0.587, 0.114));
                return lerp(color, half4(luminosity, luminosity, luminosity, color.a), _Ratio) * i.color;
            }
            ENDHLSL
        }
    }
}