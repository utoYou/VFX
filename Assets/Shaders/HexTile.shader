Shader "Custom/HexTile"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TriToHex ("Tri to Hex", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Overlay"
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

            static float r3 = 1.73205080756;    // sqrt(3)の値
            static float r3i = 0.57735026919;   // 1/sqrt(3)の値

            // 直交<->斜交の座標変換行列
            static float2x2 tri2cart = float2x2(1., .5, 0., r3 * .5);
            static float2x2 cart2tri = float2x2(1., -r3i, 0., r3i * 2.);

            // 直交<->斜交の座標変換行列
            static float2x2 cart2hex = float2x2(2, 0, -1, r3i);
            static float2x2 hex2cart = float2x2(.5, 0, r3 * .5, r3);

            sampler2D _MainTex;
            half _TriToHex;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float2 triCoordinate(float2 uv, float scale = 1.)
            {
                uv = mul(cart2tri, uv * scale);
                float2 index = floor(uv);
                float2 pos = frac(uv);

                // 三角形の重心座標を計算
                index += (2. - step(pos.x + pos.y, 1.)) / 3.;
                return mul(tri2cart, index) / scale;
            }

            float2 hexCoordinate(float2 uv, float scale = 1.)
            {
                uv = mul(cart2hex, uv * scale);
                float2 index = floor(uv);
                float2 pos = frac(uv);

                // 上半分かどうか
                float upper = 1 - step(pos.x + pos.y * 3., 2.);
                // 領域は点対称なので上半分なら折り返す
                pos = lerp(pos, 1. - pos, upper);
                // 右側の六角形に含まれるかどうか、折り返しも考慮して判定
                float right = 1. - abs(upper - step(pos.x * 2. + pos.y * 3., 1.));

                // 六角形の重心座標を計算
                index.x += right;
                index.y += upper;

                return mul(hex2cart, index) / scale;
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float2 triUV = triCoordinate(i.uv, 4.);
                float2 hexUV = hexCoordinate(i.uv, 4.);
                return half4(lerp(triUV, hexUV, _TriToHex), 0, 1);
            }
            ENDHLSL
        }
    }
}