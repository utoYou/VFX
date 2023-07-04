Shader "Custom/Halftone"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HalftoneScale ("Halftone Scale", Range(0.001, 0.1)) = 0.02
        _ShadeColor ("Shade Color", Color) = (0.5, 0.5, 0.5)
    }
    SubShader
    {
        Tags {
            "RenderType"="Geometry"
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
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float3 normal : NORMAL;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _HalftoneScale;
            half3 _ShadeColor;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.positionHCS);
                o.normal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // wで除算して0~1の値にする
                half2 screenPos = i.screenPos.xy / i.screenPos.w;
                // 画面サイズのy幅がx幅の何倍かを計算する
                float aspect = _ScreenParams.x / _ScreenParams.y;
                // 各区画のサイズ
                half2 cellSize = half2(_HalftoneScale, _HalftoneScale * aspect);

                // 対象ピクセルが属する区画の中心点を計算する
                half2 cellCenter;
                cellCenter.x = floor(screenPos.x / cellSize.x) * cellSize.x + cellSize.x / 2;
                cellCenter.y = floor(screenPos.y / cellSize.y) * cellSize.y + cellSize.y / 2;

                // 区画の中心点との差分ベクトルを0~1の範囲に補正する
                half2 diff = screenPos - cellCenter;
                diff.x /= cellSize.x;
                diff.y /= cellSize.y;

                // ライト情報
                Light light = GetMainLight();
                // ピクセルの法線とライトの方向の内積を計算する
                float threshold = 1 - dot(i.normal, light.direction);

                // 対象ピクセルと区画の中心点の距離が閾値より小さかったら色を塗る
                col.rgb *= lerp(1, _ShadeColor, step(length(diff), threshold));
                return col;
            }
            ENDHLSL
        }
    }
}