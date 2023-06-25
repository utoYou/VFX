Shader "Custom/StencilWrite"
{
    Properties
    {
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

            ZWrite Off
            ColorMask 0     // 常にRGBAに書き込まない設定
            Stencil 
            {
              Ref 2         // 描画する時に2の値を書き込む
              Comp Always   // ステンシルテストが常に通る
              Pass Replace  // ステンシルテストが通ったら書き換える
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            void frag (Varyings i)
            {
                
            }
            ENDHLSL
        }
    }
}