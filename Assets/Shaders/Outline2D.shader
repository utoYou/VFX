Shader "Custom/Outline2D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineSpread ("Outline Spread", Range(0, 0.01)) = 0.007
        _Color ("Color", Color) = (1, 1, 1, 1)
        _ColorX ("Color2", Color) = (1, 1, 1, 1)
        _Alpha ("Alpha", Range(0, 1)) = 1.0
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
            Cull Off
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
                float4 positionHCS : SV_POSITION;
                half4 color : COLOR;
            };

            sampler2D _MainTex;
            float _OutlineSpread;
            half4 _Color;
            half4 _ColorX;
            float _Alpha;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 mainColor = (tex2D(_MainTex, i.uv + float2(-_OutlineSpread, _OutlineSpread))
                   + tex2D(_MainTex, i.uv + float2(_OutlineSpread, -_OutlineSpread))
                   + tex2D(_MainTex, i.uv + float2(_OutlineSpread, _OutlineSpread))
                   + tex2D(_MainTex, i.uv - float2(_OutlineSpread, _OutlineSpread)));
                mainColor.rgb = _Color.rgb;

                half4 addColor = tex2D(_MainTex, i.uv) * i.color;

                if (mainColor.a > 0.40)
                {
                    mainColor = _ColorX;
                }
                if (addColor.a > 0.40)
                {
                    mainColor = addColor;
                    mainColor.a = addColor.a;
                }

                return mainColor * i.color.a;
            }
            ENDHLSL
        }
    }
}