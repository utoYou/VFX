Shader "Custom/SpecularReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularTex ("Specular Texture", 2D) = "black" {}
        _SpecularInt ("Specular Intensity", Range(0, 1)) = 1
        _SpecularPow ("Specular Power", Range(1, 128)) = 64
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
                float3 viewDirWS : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _SpecularTex;
            float _SpecularInt;
            float _SpecularPow;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float3 SpecularShading
            (
                float3 colorRefl,
                float specularInt,
                float3 normal,
                float3 lightDir,
                float3 viewDir,
                float specularPow
            )
            {
                float3 h = normalize(lightDir + viewDir); // halfway
                return colorRefl * specularInt * pow(max(0, dot(normal, h)), specularPow);
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.viewDirWS = GetWorldSpaceViewDir(v.positionOS.xyz);   // ここOSじゃなくてWSかも
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.positionHCS.z);
                o.color = v.color;
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                float3 viewDir = i.viewDirWS;
                Light light = GetMainLight();
                half3 colorRefl = light.color.rgb;
                float3 lightDir = normalize(light.direction);
                half3 specCol = tex2D(_SpecularTex, i.uv) * colorRefl;
                half3 specular = SpecularShading(specCol, _SpecularInt, i.normalWS, lightDir, viewDir, _SpecularPow);
                col.rgb += specular;
                return col;
            }
            ENDHLSL
        }
    }
}