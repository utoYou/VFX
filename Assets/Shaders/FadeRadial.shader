Shader "Custom/FadeRadial"
{
    Properties
    {
        // [NoScaleOffset]
        _MainTex ("Texture", 2D) = "white" {}
        _Threthold ("Threthold", Range(0, 1)) = 0
        _CircleCenterX ("Circle Center X", Range(0, 1)) = 0.5
        _CircleCenterY ("Circle Center Y", Range(0, 1)) = 0.5
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
            float4 _MainTex_TexelSize;
            half _Threthold;
            half _CircleCenterX;
            half _CircleCenterY;

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
                // Textureサイズによって円の比率が歪むので正円になるようにする
                half resolution = _MainTex_TexelSize.z / _MainTex_TexelSize.w;
                half2 center = half2(_CircleCenterX, _CircleCenterY);
                half2 targetUV = i.uv;
                targetUV -= center;
                targetUV.x *= resolution;
                targetUV += center;
                half d = distance(center, targetUV);
                // stepの引数の順番を変えると印象が変わる
                half isMasked = step(_Threthold, d);
                half4 col = tex2D(_MainTex, i.uv);
                return isMasked ? half4(0, 0, 0, 1) : col;
            }
            ENDHLSL
        }
    }
}