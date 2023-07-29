Shader "Custom/Lambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightInt ("Light Intensity", Range(0, 1)) = 1
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

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                // フォグの計算で使うfog factor用のinterpolator
                float fogFactor: TEXCOORD1;
                float4 positionHCS : SV_POSITION;
                half4 color : COLOR;
                float3 normalWS: NORMAL;
            };

            sampler2D _MainTex;
            float _LightInt;
            float4 _LightColor0;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float3 LambertShading
            (
                float3 colorRefl,
                float lightInt,
                float3 normal,
                float3 lightDir
            )
            {
                return colorRefl * lightInt * max(0, dot(normal, lightDir));
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.positionHCS.z);
                o.color = v.color;
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                Light light = GetMainLight();
                half3 colorRefl = light.color.rgb;
                half3 lightDir = light.direction.rgb;
                half3 diffuse = LambertShading(colorRefl, _LightInt, i.normalWS, lightDir);
                col.rgb *= diffuse;
                return col;
            }
            ENDHLSL
        }
    }
}