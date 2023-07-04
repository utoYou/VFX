// 実装的にアルファを含む画像では見た目を損なうかも
Shader "Custom/Ripple"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress ("Progress", Range(0, 1)) = 1.0
        _Power ("Power", Range(1.0, 3)) = 3
        _MinSpeed ("Min Speed", float) = 10
        _MaxSpeed ("Max Speed", float) = 90
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
            half _Progress;
            half _Power;
            half _MinSpeed;
            half _MaxSpeed;

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
                float2 uv = i.uv;

                uv *= 2.0;
                uv -= float2(1, 1);

                half len = length(uv);
                half rSpeed = lerp(_MaxSpeed, _MinSpeed, len);

                half sinX = sin((1 - _Progress) * rSpeed);
                half cosX = cos((1 - _Progress) * rSpeed);

                float2 trs = mul(uv, float2x2(float2(cosX, sinX), float2(-sinX, cosX)));
                trs /= pow(_Progress, _Power);

                trs += float2(1, 1);
                trs /= 2.0;
                // if (trs.x > 1 || trs.x < 0 || trs.y > 1 || trs.y < 0)
                // {
                //     discard;
                // }
                return tex2D(_MainTex, trs);
            }
            ENDHLSL
        }
    }
}