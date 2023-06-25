Shader "Custom/Toon"
{
    Properties
    {
        _Color ("Color", Color) = (0.5, 0.65, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]
        _AmbientColor ("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
        [HDR]
        _SpecularColor ("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
        _Glossiness ("Glosiness", Float) = 32
        [HDR]
        _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "IgnoreProjector"="True"
            "RenderPipeline"="UniversalPipeline"
            "LightMode"="ForwardBase"
            "PassFlags"="OnlyDirectional"
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
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #define _MAIN_LIGHT_SHADOWS_CASCADE
            #define _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
                float4 shadowCoord : TEXCOORD2;
                float4 positionHCS : SV_POSITION;
                float3 normal : NORMAL;
            };

            half4 _Color;
            sampler2D _MainTex;
            half4 _AmbientColor;
            half4 _SpecularColor;
            float _Glossiness;
            half4 _RimColor;
            float _RimAmount;
            float _RimThreshold;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.shadowCoord = GetShadowCoord(vertexInput);
                o.viewDirWS = GetWorldSpaceViewDir(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(i.viewDirWS);
                Light light = GetMainLight(i.shadowCoord);    // i.shadowCoordを渡すことでRecieveShadow込みのLightを取得

                // 光の強さ&色
                float NdotL = dot(light.direction, normal);
                float lightIntensity = smoothstep(0, 0.01, NdotL);
                half4 lightColor = lightIntensity * half4(light.color, 1);

                // 鏡面反射光
                float3 halfVector = normalize(_MainLightPosition + viewDir);
                float NdotH = dot(normal, halfVector);
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensity * _SpecularColor;

                // リムライト
                float4 rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;

                return tex2D(_MainTex, i.uv) * _Color * (_AmbientColor + lightColor + specular + rim + light.shadowAttenuation);
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}